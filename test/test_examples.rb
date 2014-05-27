require File.expand_path('../helper', __FILE__)

class TestExamples < MiniTest::Test
  def setup
    @interpreter = SlideField::Interpreter.new
    @path = File.expand_path '../examples', __dir__
  end

  def test_minimal
    @interpreter.run_file @path + "/minimal.sfp"
    assert_equal @path + "/", @interpreter.root.include_path
    assert_equal @path + "/", @interpreter.root[:layout].first.include_path
  end

  def test_complete
    @interpreter.run_file @path + "/complete.sfp"
  end

  def test_parse_error
    error = assert_raises SlideField::ParseError do
      @interpreter.run_file @path + "/test/parse_error.sfp"
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
      @interpreter.run_string '\\include "test/parse_error.sfp"', @path
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
      @interpreter.run_file @path + "/test/recursive_include.sfp"
    end

    assert_equal "[recursive_include.sfp] File already interpreted: '#{@path}/test/recursive_include.sfp'", error.message
  end

  def test_include_subfolder
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + "/test/sub/include_parent.sfp"
    end

    assert_match /^\[include_parent.sfp\] \[..\/unknown_command.sfp\] /, error.message

    error = assert_raises SlideField::ParseError do
      @interpreter.run_file @path + "/test/parse_error.sfp"
    end

    assert_match /^\[parse_error.sfp\] /, error.message
  end
end
