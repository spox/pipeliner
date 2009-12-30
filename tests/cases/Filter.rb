require 'pipeliner'
require 'test/unit'

class FilterTest < Test::Unit::TestCase
    def setup
    end
    def teardown
    end

    class MyFilter < Pipeliner::Filter
        def do_filter(o)
            return [o.to_sym]
        end
    end
    
    def test_basic
        assert_raise(ArgumentError){ Pipeliner::Filter.new }
        a = Pipeliner::Filter.new(String)
        assert_kind_of(Pipeliner::Filter, a)
        assert_raise(ArgumentError){ a.filter([1,2]) }
        assert_raise(NoMethodError){ a.filter('test') }
    end

    def test_custom
        a = MyFilter.new(String)
        assert_kind_of(Array, a.filter('test'))
        assert_equal([:test], a.filter('test'))
    end
end