require File.expand_path '../helper', __FILE__

class TestLocation < MiniTest::Test
  def test_context
    context = SF::Context.new 'context label', 'include_path', 'object', 'source code'

    assert_equal 'context label', context.label
    assert_equal 'include_path', context.include_path
    assert_equal 'object', context.object
    assert_equal 'source code', context.source
  end

  def test_native
    loc = SF::Location.new
    assert loc.native?

    loc = SF::Location.new nil, 4, 2
    assert loc.native?

    loc = SF::Location.new SF::Context.new
    refute loc.native?
  end

  def test_default_context
    loc = SF::Location.new

    assert_instance_of SF::Context, loc.context
    assert_nil loc.context.object
  end

  def test_line_and_column
    location = SF::Location.new nil, 4, 2
    
    assert_equal [4, 2], location.line_and_column
  end

  def test_compare
    control = SF::Location.new

    assert control == SF::Location.new
    refute control == SF::Location.new(:context, 0, 0)
    refute control == SF::Location.new(nil, 1, 0)
    refute control == SF::Location.new(nil, 0, 1)
  end

  def test_to_s
    context = SF::Context.new
    context.label = 'label'

    location = SF::Location.new context, 4, 2

    assert_equal 'label:4:2', location.to_s
  end

  def test_to_s_native
    location = SF::Location.new

    assert_equal '<native code>', location.to_s
  end
end
