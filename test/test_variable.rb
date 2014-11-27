require File.expand_path '../helper', __FILE__

SF::Object.define :type1 do end
SF::Object.define :type2 do end

class TestVariable < MiniTest::Test
  def test_create
    loc = SF::Location.new
    var = SF::Variable.new 1, loc

    assert_equal 1, var.value
    assert_same loc, var.location
  end

  def test_default_location
    var = SF::Variable.new 1

    assert var.location.native?
  end

  def test_nil
    var = SF::Variable.new String
    assert var.value.nil?
  end

  def test_compatible
    var = SF::Variable.new 'hello'

    assert var.compatible_with? 'world'
    refute var.compatible_with? 42
  end

  def test_nil_compatible
    var = SF::Variable.new String

    assert var.compatible_with? 'world'
    refute var.compatible_with? 42
  end

  def test_compatible_object
    var = SF::Variable.new SF::Object.new(:type1)

    assert var.compatible_with? SF::Object.new(:type1)
    refute var.compatible_with? SF::Object.new(:type2)
  end

  def test_nil_compatible_object
    var = SF::Variable.new :type1

    assert var.compatible_with? SF::Object.new(:type1)
    refute var.compatible_with? SF::Object.new(:type2)
  end

  def test_value_frozen
    var = SF::Variable.new 'hello world'

    assert var.value.frozen?
  end

  def test_valid_values
    SF::Variable.new 42
    SF::Variable.new Fixnum

    SF::Variable.new 'hello world'
    SF::Variable.new String

    SF::Variable.new SF::Point.new(1, 1)
    SF::Variable.new SF::Point

    SF::Variable.new SF::Color.new(255, 255, 255, 255)
    SF::Variable.new SF::Color

    SF::Variable.new SF::Boolean.new(true)
    SF::Variable.new SF::Boolean
  end

  def test_reject_foreign_values
    assert_raises SF::ForeignValueError do
      SF::Variable.new Hash.new
    end

    assert_raises SF::ForeignValueError do
      SF::Variable.new Hash
    end
  end

  def test_type_of
    assert_equal 'boolean', SF::Variable.type_of(SF::Boolean.false)
    assert_equal 'color', SF::Variable.type_of(SF::Color.black)
    assert_equal 'integer', SF::Variable.type_of(42)
    assert_equal 'point', SF::Variable.type_of(SF::Point.zero)
    assert_equal 'string', SF::Variable.type_of('hello world')
    assert_equal 'template', SF::Variable.type_of(SF::Template.new(:a, :b))
    assert_equal "\\type1", SF::Variable.type_of(SF::Object.new(:type1))
  end

  def test_type
    assert_equal 'integer', SF::Variable.new(42).type
  end
end
