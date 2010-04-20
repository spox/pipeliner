require 'actionpool'
require 'splib'
require 'pipeliner/FilterManager'

Splib.load :Constants

module Pipeliner
    class Pipeline
        # args:: Hash containing initializations
        #   :pool =>:: ActionPool::Pool for the Pipeline to use
        #   :filters =>:: FilterManager for the Pipeline to use
        # Create a new Pipeline
        def initialize(args={})
            @pool = args[:pool] ? args[:pool] : ActionPool::Pool.new
            @hooks = {}
            @lock = Mutex.new
            @filters = args[:filters] ? args[:filters] : FilterManager.new
            if(!args[:pool])
                Kernel.at_exit do
                    close
                end
            end
        end

        # Close the pipeline
        # Note: This is important to call at the end of a script when not
        #       providing an ActionPool thread pool to the pipeline.
        #       This will ensure the thread pool is properly shutdown
        #       and avoid the script hanging.
        def close
            @pool.shutdown
            clear
        end

        # Open the pipeline
        def open
            @pool = ActionPool::Pool.new unless @pool
        end
        
        # Returns current FilterManager
        def filters
            @filters
        end

        # fm:: FilterManager
        # Set the FilterManager the Pipeline should use
        def filters=(fm)
            raise ArgumentError.new('Expecting a FilterManager') unless fm.is_a?(FilterManager)
            @filters = fm
        end

        # type:: Type of Objects to pass to object
        # object:: Object to hook to pipeline
        # method:: Method to call on object
        # block:: Block to apply to object (called without object and method set) or conditional
        # Hooks an Object into the pipeline for objects of a given type. The block can serve
        # two purposes here. First, we can hook a block to a type like so:
        #   pipeline.hook(String){|s| puts s }
        # Or, we can use the block as a conditional for calling an object's method:
        #   pipeline.hook(String, obj, :method){|s| s == 'test' }
        # In the second example, this hook will only be called if the String type object
        # matches the conditional in the block, meaning the string must be 'test'
        def hook(type, object=nil, method=nil, &block)
            raise ArgumentError.new 'Type must be provided' if type.nil?
            if(block && (block.arity > 1 || block.arity == 0))
                raise ArgumentError.new('Block must accept a parameter')
            end
            if((object && method.nil?) || (object.nil? && method))
                raise ArgumentError.new('Object AND method must be provided')
            end
            if(!block_given? && object.nil? && method.nil?)
                raise ArgumentError.new('No object information or block provided for hook')
            end
            @lock.synchronize do
                const = Splib.find_const(type)
                type = const unless const.nil?
                @hooks[type] ||= {}
                if(block_given? && object.nil? && method.nil?)
                    @hooks[type][:procs] ||= []
                    @hooks[type][:procs] << block
                else
                    name = object.class
                    method = method.to_sym
                    raise ArgumentError.new('Given object does not respond to given method') unless object.respond_to?(method)
                    @hooks[type][name] ||= []
                    @hooks[type][name] << {:object => object, :method => method, :req => !block_given? ? lambda{|x|true} : block}
                end
            end
            block_given? ? block : nil
        end

        # object:: Object or Proc to unhook from the pipeline
        # type:: Type of Objects being received
        # method:: method registered to call
        # Remove a hook from the pipeline. If the method and type are not
        # specified, the given object will be removed from all hooks
        def unhook(object, type=nil, method=nil)
            raise ArgumentError.new('Object method provided for a Proc') if object.is_a?(Proc) && method
            @lock.synchronize do
                case object
                when Proc
                    if(type)
                        @hooks[type][:procs].delete(object)
                        @hooks[type].delete(:procs) if @hooks[type][:procs].empty?
                    else
                        @hooks.each_value do |h|
                            h[:procs].delete(object)
                            h.delete(:procs) if h[:procs].empty?
                        end
                    end
                else
                    if(method.nil? && type.nil?)
                        @hooks.each_value{|v|v.delete_if{|k,z| k == object.class}}
                    else
                        raise ArgumentError.new('Type must be provided') if type.nil?
                        const = Splib.find_const(type)
                        type = const unless const.nil?
                        method = method.to_sym if method
                        name = object.class
                        raise NameError.new('Uninitialized hook type given') unless @hooks[type]
                        raise StandardError.new('No hooks found for given object') unless @hooks[type][name]
                        if(method)
                            @hooks[type][name].delete_if{|x|x[:method] == method}
                            @hooks[type].delete(name) if @hooks[type][name].empty?
                        else
                            @hooks[type].delete(name)
                        end
                    end                    
                end
                @hooks.delete_if{|k,v|v.empty?}
            end
        end

        # Return current hooks hash
        def hooks
            @lock.synchronize{ @hooks.dup }
        end

        # Remove all hooks from the pipeline
        def clear
            @lock.synchronize{ @hooks.clear }
        end

        # object:: Object to send down the pipeline
        # Send an object down the pipeline
        def <<(object)
            raise StandardError.new('Pipeline is currently closed') if @pool.nil?
            object = @filters.apply_filters(object)
            if(object)
                object.freeze
                @pool.process{ flush(object) }
            end
        end

        private

        # o:: Object to flush
        # Applies object to all matching hooks
        def flush(o)
            @hooks.keys.each do |type|
                next unless Splib.type_of?(o, type)
                @hooks[type].each_pair do |key, objects|
                    if(key == :procs)
                        objects.each{|pr| @pool.process{ pr.call(o) }}
                    else
                        objects.each{|h| @pool.process{ h[:object].send(h[:method], o) if h[:req].call(o) }}
                    end
                end
            end
            nil
        end
    end
end