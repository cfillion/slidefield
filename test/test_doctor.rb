require File.expand_path '../helper', __FILE__

class TestDoctor < MiniTest::Test
  def setup
    @klass = Class.new { include SF::Doctor }
    @instance = @klass.new
    @loc = SF::Location.new
  end

  def teardown
    SF::Doctor.bag.clear
  end

  def test_doctor
    error = @instance.send :error_at, @loc, 'message'
    assert_equal :error, error.level

    warning = @instance.send :warning_at, @loc, 'message'
    assert_equal :warning, warning.level

    assert_equal [error, warning], SF::Doctor.bag(@klass)
    assert_equal({@klass=>[error, warning]}, SF::Doctor.bag)
  end

  def test_output
    device = StringIO.new

    assert_nil SF::Doctor.output
    SF::Doctor.output = device
    assert_same device, SF::Doctor.output

    device.rewind
    assert_empty device.read

    @instance.send :error_at, @loc, 'message'

    device.rewind
    refute_empty device.read
  ensure
    SF::Doctor.output = nil
  end

  def test_repeated_output
    device = StringIO.new
    SF::Doctor.output = device

    @instance.send :error_at, @loc, 'message'
    @instance.send :error_at, @loc, 'message'

    device.rewind
    assert_equal 1, device.read.scan('message').count
  ensure
    SF::Doctor.output = nil
  end
end
