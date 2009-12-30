module Pipeliner
    class Filter
        # type of Objects filter is to be applied to
        attr_reader :type
        # t:: type of Objects filter is to be applied to
        # Create a new Filter
        def initialize(t)
            raise ArgumentError.new('Expecting Class or String') unless [Class, String].include?(t.class)
            @type = t
        end

        # o:: Object from Pipeline
        # Applies filter to Object
        def filter(o)
            raise ArgumentError.new('Wrong type supplied to filter') unless Splib.type_of?(o, @type)
            do_filter(o)
        end

        protected

        # o:: Object to be filtered
        # This is where the actual filtering takes place. This
        # is the method to overload!
        # NOTE: Objects can be filtered in any way. For a filter to
        # basically "throw away" an Object, simply return nil and the
        # Object will not be flushed down the Pipeline
        def do_filter(o)
            raise NoMethodError.new('This method has not been implemented')
        end
    end
end