require 'pipeliner'
require 'test/unit'

class FilterManagerTest < Test::Unit::TestCase
  class MyFilter < Pipeliner::Filter
    def do_filter(o)
      "#{o}: filtered"
    end
  end
  def setup
    @fm = Pipeliner::FilterManager.new
    @filter = MyFilter.new(String)
  end
  def teardown
    @fm.clear
  end

  def test_add
    @fm.add(String, @filter)
    assert_equal(1, @fm.filters[String][:filters].size)
    @fm.add(String, @filter)
    assert_equal(1, @fm.filters[String][:filters].size)
    @fm.add(String){|s|s}
    assert_equal(1, @fm.filters[String][:procs].size)
    assert_raise(ArgumentError) do
      @fm.add(String, "string")
    end
    assert_raise(ArgumentError) do
      @fm.add(Object)
    end
    @fm.clear
    assert(@fm.filters.empty?)
    @fm.add(String, @filter){|s|s}
    assert_equal(1, @fm.filters[String][:filters].size)
    assert_equal(1, @fm.filters[String][:procs].size)
  end

  def test_remove
    @fm.add(String, @filter)
    assert_equal(1, @fm.filters[String][:filters].size)
    @fm.remove(@filter, String)
    assert(!@fm.filters.has_key?(String))
    @fm.add(String, @filter)
    assert_equal(1, @fm.filters[String][:filters].size)
    @fm.remove(@filter)
    assert(!@fm.filters.has_key?(String))
    pr = @fm.add(String){|s|s}
    assert_equal(1, @fm.filters[String][:procs].size)
    @fm.remove(pr, String)
    assert(!@fm.filters.has_key?(String))
    pr = @fm.add(String){|s|s}
    assert_equal(1, @fm.filters[String][:procs].size)
    @fm.remove(pr)
    assert(!@fm.filters.has_key?(String))
  end

  def test_apply
    @fm.add(String, @filter)
    assert_equal("test: filtered", @fm.apply_filters("test"))
    assert_equal(1, @fm.apply_filters(1))
    data = "fubar"
    assert_not_same(data, @fm.apply_filters(data))
    data = [:fubar]
    assert_same(data, @fm.apply_filters(data))
    @fm.add(Fixnum){|o| "string"}
    assert_kind_of(String, @fm.apply_filters(2))
  end

  def test_clear
    @fm.add(String, @filter)
    assert_equal(1, @fm.filters[String][:filters].size)
    @fm.clear
    assert(@fm.filters.empty?)
  end
end