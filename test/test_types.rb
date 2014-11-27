require File.expand_path '../helper', __FILE__

class TestTypes < MiniTest::Test
  def test_string
    assert_equal 2, "hello\nworld".filter_lines
  end

  def test_fixnum
    assert_equal SF::Point.new(42, 0), 42.filter_x
    assert_equal SF::Point.new(0, 42), 42.filter_y

    assert_equal SF::Color.new(42, 0, 0, 0), 42.filter_r
    assert_equal SF::Color.new(0, 42, 0, 0), 42.filter_g
    assert_equal SF::Color.new(0, 0, 42, 0), 42.filter_b
    assert_equal SF::Color.new(0, 0, 0, 42), 42.filter_a
  end

  def test_boolean
    t = SF::Boolean.new true
    f = SF::Boolean.new false

    assert_same true, t.to_bool
    assert_same false, f.to_bool

    assert_equal SF::Boolean.new(true), t
    refute_equal SF::Boolean.new(false), t
  end

  def test_predefined_booleans
    assert_equal SF::Boolean.new(true), SF::Boolean.true
    assert_equal SF::Boolean.new(false), SF::Boolean.false
  end

  def test_boolean_to_string
    assert_equal 'true', SF::Boolean.new(true).to_s
    assert_equal 'false', SF::Boolean.new(false).to_s
  end

  def test_boolean_operand_mismatch
    left = SF::Boolean.new(true)
    right = 42

    refute_equal left, right
  end

  def test_point
    p = SF::Point.new 4, 2
    
    assert_equal 4, p.x
    assert_equal 4, p.filter_x

    assert_equal 2, p.y
    assert_equal 2, p.filter_y

    assert_equal [4, 2], p.to_a

    assert_equal SF::Point.new(4, 2), p
    refute_equal SF::Point.new(2, 4), p
  end

  def test_predefined_points
    assert_equal SF::Point.new(0, 0), SF::Point.zero
  end

  def test_point_operators
    left = SF::Point.new 4, 2
    right = SF::Point.new 2, 3

    assert_equal SF::Point.new(6, 5), left + right
    assert_equal SF::Point.new(2, -1), left - right
    assert_equal SF::Point.new(8, 6), left * right
    assert_equal SF::Point.new(2, 0), left / right
  end

  def test_color_operand_mismatch
    left = SF::Point.new 4, 2
    right = 42

    refute_equal left, right
    assert_raises(TypeError) { left + right }
    assert_raises(TypeError) { left - right }
    assert_raises(TypeError) { left * right }
    assert_raises(TypeError) { left / right }
  end

  def test_point_to_string
    assert_equal '4x2', SF::Point.new(4, 2).to_s
  end

  def test_color
    c = SF::Color.new 0, 1, 2, 3

    assert_equal 0, c.r
    assert_equal 0, c.filter_r

    assert_equal 1, c.g
    assert_equal 1, c.filter_g

    assert_equal 2, c.b
    assert_equal 2, c.filter_b

    assert_equal 3, c.a
    assert_equal 3, c.filter_a

    assert_equal [0, 1, 2, 3], c.to_a

    assert_equal SF::Color.new(0, 1, 2, 3), c
    refute_equal SF::Color.new(1, 2, 3, 4), c
  end

  def test_predefined_colors
    assert_equal SF::Color.new(255, 255, 255, 255), SF::Color.white
    assert_equal SF::Color.new(0, 0, 0, 255), SF::Color.black
  end

  def test_out_of_bounds_color
    assert_raises SF::ColorOutOfBoundsError do
      SF::Color.new  -1, 1, 2, 3
    end

    assert_raises SF::ColorOutOfBoundsError do
      SF::Color.new  0, 256, 2, 3
    end
  end

  def test_color_operators
    left = SF::Color.new 4, 2, 6, 8
    right = SF::Color.new 2, 2, 4, 1

    assert_equal SF::Color.new(6, 4, 10, 9), left + right
    assert_equal SF::Color.new(2, 0, 2, 7), left - right
    assert_equal SF::Color.new(8, 4, 24, 8), left * right
    assert_equal SF::Color.new(2, 1, 1, 8), left / right
  end

  def test_color_operand_mismatch
    left = SF::Color.new 4, 2, 6, 8
    right = 42

    refute_equal left, right
    assert_raises(TypeError) { left + right }
    assert_raises(TypeError) { left - right }
    assert_raises(TypeError) { left * right }
    assert_raises(TypeError) { left / right }
  end

  def test_color_to_string
    assert_equal '#C0FF33FF', SF::Color.new(192, 255, 51, 255).to_s
  end

  def test_template
    tpl = SF::Template.new :context, :tokens

    assert_equal :context, tpl.context
    assert_equal :tokens, tpl.statements
  end

  def test_template_to_string
    tpl = SF::Template.new :context, :tokens
    assert_equal '<Template>', tpl.to_s
  end
end
