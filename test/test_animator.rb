require File.expand_path '../helper', __FILE__

class TestAnimator < MiniTest::Test
  def setup
    @animator = SlideField::Animator.new [1000,500]
    @assert_number = 0
  end

  def get_object(anim_name, duration, enter = true, leave = true)

    a = SlideField::ObjectData.new :animation, 'animation loc'
    a.set :name, anim_name, 'name loc', :string
    a.set :duration, duration, 'duration loc', :integer
    a.set :enter, enter, 'enter loc', :boolean
    a.set :leave, leave, 'leave loc', :boolean

    obj = SlideField::ObjectData.new :object, 'object loc'
    a << obj
    obj
  end

  def assert_animation(anim_name, duration, tests, enter = true, leave = true, need_redraw = true)
    obj = get_object anim_name, duration, enter, leave
    tests.each_with_index {|test, index|
      time, current, forward, assertions = test

      @animator.frame time, current, forward do
        tr = @animator.transform obj

        assertions.each {|k,v|
          assert_same v, tr[k], "tr.#{k} in test #{index + 1}"
        }
      end

      assert_equal need_redraw, @animator.need_redraw?,
        "animator.need_redraw? in test #{index + 1}"
    }
  end

  def test_need_redraw
    obj = get_object 'fade', 50

    # initial value
    assert @animator.need_redraw?

    # start animation
    @animator.frame 0, true, false do
      @animator.transform obj
    end
    assert @animator.need_redraw?

    # end animation
    @animator.frame 50, true, false do
      @animator.transform obj
    end
    assert @animator.need_redraw?

    # finish the job
    @animator.frame 100, true, false do
      @animator.transform obj
    end
    refute @animator.need_redraw?

    # prepare to restart over
    @animator.reset
    assert @animator.need_redraw?
  end

  def test_outside_frame
    @animator.frame(nil, nil, nil) {}

    error = assert_raises RuntimeError do
      @animator.transform nil
    end

    assert_equal "Can not animate outside a frame", error.message
  end

  def test_unsupported
    error = assert_raises SlideField::RuntimeError do
      assert_animation 'aaaa', 0, [0, true, false, {}]
    end

    assert_equal "Unsupported animation 'aaaa'", error.message
  end

  def test_fade_in
    assert_animation 'fade', 100, [
      [0, true, nil, {:opacity=>0.0}],
      [50, true, nil, {:opacity=>0.5}],
      [100, true, nil, {:opacity=>1.0}],
    ]
  end

  def test_fade_out
    assert_animation 'fade', 100, [
      [0, false, nil, {:opacity=>1.0}],
      [50, false, nil, {:opacity=>0.5}],
      [100, false, nil, {:opacity=>0.0}],
    ]
  end

  def test_slide_right_current_forward
    assert_animation 'slide right', 100, [
      [0, true, true, {:x_offset=>-1000.0}],
      [50, true, true, {:x_offset=>-500.0}],
      [100, true, true, {:x_offset=>0.0}],
    ]
  end

  def test_slide_right_current_backward
    assert_animation 'slide right', 100, [
      [0, true, false, {:x_offset=>1000.0}],
      [50, true, false, {:x_offset=>500.0}],
      [100, true, false, {:x_offset=>0.0}],
    ]
  end

  def test_slide_right_previous_forward
    assert_animation 'slide right', 100, [
      [0, false, true, {:x_offset=>0.0}],
      [50, false, true, {:x_offset=>500.0}],
      [100, false, true, {:x_offset=>1000.0}],
    ]
  end

  def test_slide_right_previous_backward
    assert_animation 'slide right', 100, [
      [0, false, false, {:x_offset=>0.0}],
      [50, false, false, {:x_offset=>-500.0}],
      [100, false, false, {:x_offset=>-1000.0}],
    ]
  end

  def test_slide_left_current_forward
    assert_animation 'slide left', 100, [
      [0, true, true, {:x_offset=>1000.0}],
      [50, true, true, {:x_offset=>500.0}],
      [100, true, true, {:x_offset=>0.0}],
    ]
  end

  def test_slide_left_current_backward
    assert_animation 'slide left', 100, [
      [0, true, false, {:x_offset=>-1000.0}],
      [50, true, false, {:x_offset=>-500.0}],
      [100, true, false, {:x_offset=>0.0}],
    ]
  end

  def test_slide_left_previous_forward
    assert_animation 'slide left', 100, [
      [0, false, true, {:x_offset=>0.0}],
      [50, false, true, {:x_offset=>-500.0}],
      [100, false, true, {:x_offset=>-1000.0}],
    ]
  end

  def test_slide_left_previous_backward
    assert_animation 'slide left', 100, [
      [0, false, false, {:x_offset=>0.0}],
      [50, false, false, {:x_offset=>500.0}],
      [100, false, false, {:x_offset=>1000.0}],
    ]
  end

  def test_slide_down_current_forward
    assert_animation 'slide down', 100, [
      [0, true, true, {:y_offset=>-500.0}],
      [50, true, true, {:y_offset=>-250.0}],
      [100, true, true, {:y_offset=>0.0}],
    ]
  end

  def test_slide_down_current_backward
    assert_animation 'slide down', 100, [
      [0, true, false, {:y_offset=>500.0}],
      [50, true, false, {:y_offset=>250.0}],
      [100, true, false, {:y_offset=>0.0}],
    ]
  end

  def test_slide_down_previous_forward
    assert_animation 'slide down', 100, [
      [0, false, true, {:y_offset=>0.0}],
      [50, false, true, {:y_offset=>250.0}],
      [100, false, true, {:y_offset=>500.0}],
    ]
  end

  def test_slide_down_previous_backward
    assert_animation 'slide down', 100, [
      [0, false, false, {:y_offset=>0.0}],
      [50, false, false, {:y_offset=>-250.0}],
      [100, false, false, {:y_offset=>-500.0}],
    ]
  end

  def test_slide_up_current_forward
    assert_animation 'slide up', 100, [
      [0, true, true, {:y_offset=>500.0}],
      [50, true, true, {:y_offset=>250.0}],
      [100, true, true, {:y_offset=>0.0}],
    ]
  end

  def test_slide_up_current_backward
    assert_animation 'slide up', 100, [
      [0, true, false, {:y_offset=>-500.0}],
      [50, true, false, {:y_offset=>-250.0}],
      [100, true, false, {:y_offset=>0.0}],
    ]
  end

  def test_slide_up_previous_forward
    assert_animation 'slide up', 100, [
      [0, false, true, {:y_offset=>0.0}],
      [50, false, true, {:y_offset=>-250.0}],
      [100, false, true, {:y_offset=>-500.0}],
    ]
  end

  def test_slide_up_previous_backward
    assert_animation 'slide up', 100, [
      [0, false, false, {:y_offset=>0.0}],
      [50, false, false, {:y_offset=>250.0}],
      [100, false, false, {:y_offset=>500.0}],
    ]
  end

  def test_zoom_in
    assert_animation 'zoom', 100, [
      [0, true, nil, {:scale=>0.0}],
      [50, true, nil, {:scale=>0.5}],
      [100, true, nil, {:scale=>1.0}],
    ]
  end

  def test_zoom_out
    assert_animation 'zoom', 100, [
      [0, false, nil, {:scale=>1.0}],
      [50, false, nil, {:scale=>0.5}],
      [100, false, nil, {:scale=>0.0}],
    ]
  end

  def test_enter_disabled_forward
    assert_animation 'fade', 100, [
      [0, true, true, {:opacity=>1.0}],
      [50, true, true, {:opacity=>1.0}],
      [100, true, true, {:opacity=>1.0}],
    ], false, true, false
  end

  def test_enter_disabled_backward
    assert_animation 'fade', 100, [
      [0, false, false, {:opacity=>1.0}],
      [50, false, false, {:opacity=>1.0}],
      [100, false, false, {:opacity=>1.0}],
    ], false, true, false
  end

  def test_leave_disabled_forward
    assert_animation 'fade', 100, [
      [0, false, true, {:opacity=>1.0}],
      [50, false, true, {:opacity=>1.0}],
      [100, false, true, {:opacity=>1.0}],
    ], true, false, false
  end

  def test_leave_disabled_backward
    assert_animation 'fade', 100, [
      [0, true, false, {:opacity=>1.0}],
      [50, true, false, {:opacity=>1.0}],
      [100, true, false, {:opacity=>1.0}],
    ], true, false, false
  end
end
