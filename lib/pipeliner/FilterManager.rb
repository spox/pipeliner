require 'pipeliner/Filter'
require 'thread'

module Pipeliner
  class FilterManager
    # Create a new FilterManager
    def initialize
      @filters = {}
      @lock = Mutex.new
    end

    # type:: Object type to apply filter to
    # filter:: Pipeline::Filter to add
    # Add a Filter to be applied to the given types
    def add(type, filter=nil, &block)
      if((filter.nil? && !block_given?) || (filter && !filter.is_a?(Filter)))
        raise ArgumentError.new('Filter or proc must be provided for filter')
      end
      const = Splib.find_const(type)
      type = const unless const.nil?
      @lock.synchronize do
        @filters[type] ||= {}
      end
      if(block_given?)
        unless(block.arity == 1 || block.arity < 0)
          raise ArgumentError.new('Block must accept a parameter')
        end
        @lock.synchronize do
          @filters[type][:procs] ||= []
          unless(@filters[type][:procs].include?(block))
            @filters[type][:procs] << block
          end
        end
      end
      if(filter)
        @lock.synchronize do
          unless(@filters[type].include?(filter))
            @filters[type][:filters] ||= []
            unless(@filters[type][:filters].include?(filter))
              @filters[type][:filters] << filter
            end
          end
        end
      end
      filter ? block_given? ? [filter, block] : filter : block
    end

    # filter:: Pipeline::Filter to remove
    # type:: Object type filter is applied to. 
    # Remove Filter from given type. If no type is given all references
    # to the given filter will be removed
    def remove(filter, type=nil)
      if(type)
        const = Splib.find_const(type)
        type = const unless const.nil?
      end
      @lock.synchronize do
        (type ? [@filters[type]] : @filters.values).each do |set|
          [:filters, :procs].each do |t|
            if(set[t])
              set[t].delete_if{|v| v == filter}
              set.delete(t) if set[t].empty?
            end
          end
        end
        @filters.delete_if{|k,v|v.empty?}
      end
      nil
    end

    # type:: Object types
    # Return filters of given type or all filters
    # if not type is supplied
    def filters(type=nil)
      unless(type)
        @filters.dup
      else
        const = Splib.find_const(type)
        type = const unless const.nil?
        @filters[type] ? @filters[type].dup : nil
      end
    end

    # o:: Object to apply filters to
    # Applies any Filters applicable to object type
    def apply_filters(o)
      @filters.keys.find_all{|type| Splib.type_of?(o, type)}.each do |type|
        @filters[type].each_pair do |k,v|
          begin
            case k
            when :filters
              v.each{|f|o = f.filter(o)}
            when :procs
              v.each{|pr|o = pr.call(o)}
            end
          rescue ArgumentError
            # ignore this
          end
        end
      end
      o
    end

    # Remove all filters
    def clear
      @filters.clear
    end
  end
end