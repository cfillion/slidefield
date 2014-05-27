require File.expand_path('../helper', __FILE__)

class TestExamples < MiniTest::Test
  def setup
    @interpreter = SlideField::Interpreter.new
    @path = File.expand_path '../examples', __dir__
  end

  def test_minimal
    @interpreter.run_file @path + "/minimal.sfp"
  end

  def test_complete
    @interpreter.run_file @path + "/complete.sfp"
  end

  def test_parse_error
    error = assert_raises SlideField::ParseError do
      @interpreter.run_file @path + "/wrong/parse_error.sfp"
    end

    assert_match /^\[parse_error.sfp\] /, error.message
  end

  def test_include_relative
    @interpreter.run_string '\\include "minimal.sfp"', @path
  end

  def test_include_absolute
    @interpreter.run_string '\\include "' + @path + '/minimal.sfp"'
  end

  def test_include_parse_error
    error = assert_raises SlideField::ParseError do
      @interpreter.run_string '\\include "wrong/parse_error.sfp"', @path
    end

    assert_match /^\[input\] \[parse_error.sfp\] /, error.message
  end

  def test_reparse
    @interpreter.run_file @path + "/minimal.sfp"

    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + "/minimal.sfp"
    end

    assert_equal "File already interpreted: '#{@path}/minimal.sfp'", error.message
  end

  def test_recursive_include
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + "/wrong/recursive_include.sfp"
    end

    assert_equal "[recursive_include.sfp] File already interpreted: '#{@path}/wrong/recursive_include.sfp'", error.message
  end

  def test_include_subfolder
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + "/wrong/sub/include_parent.sfp"
    end

    assert_match /^\[include_parent.sfp\] \[..\/unknown_command.sfp\] /, error.message

    error = assert_raises SlideField::ParseError do
      @interpreter.run_file @path + "/wrong/parse_error.sfp"
    end

    assert_match /^\[parse_error.sfp\] /, error.message
  end
end
