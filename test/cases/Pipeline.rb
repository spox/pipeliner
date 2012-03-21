require 'pipeliner'
require 'test/unit'

class PipelineTest < Test::Unit::TestCase
  class Tester
    def initialize
      @m = []
    end
    def method(s)
      @m << s
    end
    def messages
      @m
    end
  end
  def setup
    @pipeline = Pipeliner::Pipeline.new
  end
  def teardown
    @pipeline.filters.clear
    @pipeline.clear
    @pipeline.close
  end
  def test_filters
    assert_kind_of(Pipeliner::FilterManager, @pipeline.filters)
  end
  def test_set_filters
    fm = Pipeliner::FilterManager.new
    assert_not_same(fm, @pipeline.filters)
    @pipeline.filters = fm
    assert_same(fm, @pipeline.filters)
  end
  def test_hook_addition
    assert_raise(ArgumentError){ @pipeline.hook(String) }
    assert_raise(ArgumentError){ @pipeline.hook(String){ true } } if RUBY_VERSION >= '1.9.0'
    assert_raise(ArgumentError){ @pipeline.hook(String){|a,b| true} }
    assert_kind_of(Proc, @pipeline.hook(String){|a| true })
    assert_kind_of(Proc, @pipeline.hook(String){|a, *b| true })
    assert_kind_of(Proc, @pipeline.hook(String){|*a| true })
    assert_equal(1, @pipeline.hooks.size)
    assert_equal(3, @pipeline.hooks[String][:procs].size)
    @pipeline.clear
    assert(@pipeline.hooks.empty?)
    object = Tester.new
    assert_nil(@pipeline.hook(String, object, :method))
    assert_equal(1, @pipeline.hooks[String][object.class].size)
  end
  def test_hook_deletion
    pr = @pipeline.hook(String){|a| true}
    assert_kind_of(Proc, pr)
    assert_equal(1, @pipeline.hooks[String][:procs].size)
    @pipeline.unhook(pr, String)
    assert(@pipeline.hooks.empty?)
    object = Tester.new
    @pipeline.hook(String, object, :method)
    assert_equal(1, @pipeline.hooks[String].size)
    @pipeline.unhook(object, String, :method)
    assert(@pipeline.hooks.empty?)
    @pipeline.hook(String, object, :method)
    assert_equal(1, @pipeline.hooks[String].size)
    @pipeline.unhook(object, String)
    assert(@pipeline.hooks.empty?)
    @pipeline.hook(String, object, :method)
    assert_equal(1, @pipeline.hooks[String].size)
    @pipeline.unhook(object)
    assert(@pipeline.hooks.empty?)
    @pipeline.hook(String, object, :method)
    @pipeline.hook(Object){|a|true}
    assert_equal(2, @pipeline.hooks.size)
    @pipeline.clear
    assert(@pipeline.hooks.empty?)
  end
  def test_hook_conditional
    obj = Tester.new
    @pipeline.hook(String, obj, :method)
    @pipeline << "test"
    sleep(0.01)
    assert_equal(1, obj.messages.size)
    @pipeline.hook(String, obj, :method){|s| s == 'test' }
    @pipeline << "fubar"
    sleep(0.01)
    assert_equal(2, obj.messages.size)
    @pipeline << "test"
    sleep(0.01)
    assert_equal(4, obj.messages.size)
  end
  def test_flush
    out = []
    assert(out.empty?)
    @pipeline.hook(String){|x|out << x}
    assert_equal(1, @pipeline.hooks.size)
    @pipeline << "Fubar"
    sleep(0.01)
    assert_equal(1, out.size)
    assert_equal("Fubar", out.pop)
    @pipeline << 100
    sleep(0.01)
    assert(out.empty?)
    object = Tester.new
    @pipeline.hook(String, object, :method)
    @pipeline.hook(Fixnum, object, :method)
    assert_equal(2, @pipeline.hooks[String].size)
    assert_equal(2, @pipeline.hooks.size)
    @pipeline << 'test'
    sleep(0.01)
    assert_equal(object.messages.pop, out.pop)
    @pipeline << 1
    sleep(0.01)
    assert(out.empty?)
    assert_equal(1, object.messages.pop)
  end
  def test_filters
    out = []
    @pipeline.filters.add(String){|s|10}
    @pipeline.hook(Object){|s|out << s}
    @pipeline << 'fubar'
    sleep(0.01)
    assert(out.include?(10))
    assert(!out.include?('fubar'))
    @pipeline.filters.clear
    out.clear
    @pipeline.filters.add(String){|s|nil}
    @pipeline << 'test'
    assert(out.empty?)
  end
end