require File.expand_path '../helper', __FILE__

SF::Object.define :type1 do end
SF::Object.define :type2 do end

class TestVariable < MiniTest::Test
  def test_create
    loc = SF::Location.new
    var = SF::Token.new 1, loc

    assert_equal 1, var.value
    assert_same loc, var.location
  end

  def test_default_location
    var = SF::Token.new 1

    assert var.location.native?
  end

  def test_converters
    assert_equal 1, SF::Token.new(1).to_i
    assert_equal '1', SF::Token.new(1).to_s
    assert_equal :a, SF::Token.new('a').to_sym
  end

  def test_compare
    control = SF::Token.new 42

    assert control == SF::Token.new(42)
    refute control == SF::Token.new(42, SF::Location.new(nil, 1, 1))
    refute control == SF::Token.new(:a)

    assert control == SF::Variable.new(42)
  end

  def test_compare_to_value
    control = SF::Token.new 42

    assert control == 42
    refute control == 1
  end

  def test_gate_passthrough
    tk = SF::Token.new nil

    assert_same tk, SF::Token[tk]
  end

  def test_gate_cast
    loc = SF::Location.new
    tk = SF::Token[42, loc]
    var = SF::Variable[42, loc]

    assert_instance_of SF::Token, tk
    assert_equal 42, tk.value
    assert_same loc, tk.location

    assert_instance_of SF::Variable, var
  end
end
