require File.expand_path '../helper', __FILE__

SF::Object.define :type1 do end
SF::Object.define :type2 do end

class TestVariable < MiniTest::Test
  include DoctorHelper

  def diagnostics
    SF::Doctor.bag SF::Variable
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
    error = assert_raises SF::ForeignValueError do
      SF::Variable.new Hash.new
    end
    assert_equal "cannot store 'Hash' in a variable", error.message

    error = assert_raises SF::ForeignValueError do
      SF::Variable.new Hash
    end
    assert_equal "cannot store 'Hash' in a variable", error.message
  end

  def test_type_of
    assert_equal :boolean, SF::Variable.type_of(SF::Boolean.false)
    assert_equal :color, SF::Variable.type_of(SF::Color.black)
    assert_equal :integer, SF::Variable.type_of(42)
    assert_equal :point, SF::Variable.type_of(SF::Point.zero)
    assert_equal :string, SF::Variable.type_of('hello world')
    assert_equal :template, SF::Variable.type_of(SF::Template.new(:a, :b))
    assert_equal "\\type1", SF::Variable.type_of(SF::Object.new(:type1))
  end

  def test_instance_type
    assert_equal :integer, SF::Variable.new(42).type
  end

  def test_apply_operator
    left = SF::Variable.new 32
    right = SF::Variable.new 64

    retval = left.apply :+, right
    wtoken = left.apply SF::Token.new(:+), right

    assert_equal 96, retval.value
    assert_same right.location, retval.location
    assert_equal retval, wtoken
  end

  def test_wrong_type
    left = SF::Variable.new "string"
    right = SF::Variable.new SF::Boolean.true

    retval = left.apply :+, right
    assert_equal false, retval

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "incompatible operands ('string' + 'boolean')", error.message
    assert_equal right.location, error.location
  end

  def test_invalid_operator
    left = SF::Variable.new "hello"
    right = SF::Variable.new "world"

    token = SF::Token.new :/
    assert_equal false, left.apply(token, right)
    assert_equal false, left.apply(:/, right)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "invalid operator '/=' for type 'string'", error.message
    assert_same token.location, error.location

    assert_equal error.message, diagnostics.shift.message
  end

  def test_op_negative_string_multiplication
    left = SF::Variable.new "hello world"
    right = SF::Variable.new -1

    retval = left.apply :*, right
    assert_equal false, retval

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'invalid operation (negative argument)', error.message
    assert_same right.location, error.location
  end

  def test_op_color_out_of_bounds
    left = SF::Variable.new SF::Color.new(255, 255, 255, 170)
    right = SF::Variable.new SF::Color.new(255, 255, 255, 187)

    retval = left.apply :+, right
    assert_equal false, retval

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'color is out of bounds (evaluating #FFFFFFAA + #FFFFFFBB)', error.message
    assert_same right.location, error.location
  end

  def test_op_division_by_zero
    left = SF::Variable.new 1
    right = SF::Variable.new 0

    retval = left.apply :/, right
    assert_equal false, retval

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'divison by zero (evaluating 1 / 0)', error.message
    assert_same right.location, error.location
  end

  def test_op_runtime_error
    hello = 'hello'
    def hello.+(other) raise RuntimeError end

    left = SF::Variable.new hello
    right = SF::Variable.new 'world'

    assert_raises RuntimeError do
      left.apply :+, right
    end
  end

  def test_filter
    before = SF::Variable.new SF::Point.new(4, 2)
    retval = before.filter :x
    wtoken = before.filter SF::Token.new(:x)

    assert_equal :integer, retval.type
    assert_equal 4, retval.value
    assert_equal retval, wtoken
  end

  def test_invalid_filter
    before = SF::Variable.new SF::Point.new(4, 2)

    token = SF::Token.new :bad_filter
    assert_equal false, before.filter(token)
    assert_equal false, before.filter(:bad_filter)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "unknown filter 'bad_filter' for type 'point'", error.message
    assert_same token.location, error.location

    assert_equal error.message, diagnostics.shift.message
  end
end
