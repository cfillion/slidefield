require File.expand_path('../helper', __FILE__)

class TestExamples < MiniTest::Test
  def setup
    @interpreter = SlideField::Interpreter.new
    @path = File.expand_path '../examples', __dir__
  end

  def test_minimal
    @interpreter.run_file @path + '/minimal/main.sfp'

    assert_equal @path + '/minimal/', @interpreter.root.include_path
    assert_equal 'main.sfp', @interpreter.root.context
    assert_equal @path + '/minimal/', @interpreter.root[:layout].first.include_path
    assert_equal 'main.sfp', @interpreter.root[:layout].first.context
  end

  def test_complete
    @interpreter.run_file @path + '/complete/main.sfp'

    assert_equal @path + '/complete/slides/', @interpreter.root[:slide].first.include_path
    assert_equal @path + '/complete/slides/', @interpreter.root[:slide].first.children.first.include_path
    assert_equal 'slides/mountains.sfi', @interpreter.root[:slide].first.context
    assert_equal 'slides/mountains.sfi', @interpreter.root[:slide].first.children.first.context

    assert_equal @path + '/complete/', @interpreter.root.include_path
    assert_equal 'main.sfp', @interpreter.root.context
  end

  def test_parse_error
    error = assert_raises SlideField::ParseError do
      @interpreter.run_file @path + '/test/parse_error.sfp'
    end

    assert_match /\A\[parse_error.sfp\] /, error.message
  end

  def test_include_relative
    @interpreter.run_string '\\include "minimal/main.sfp"', @path
  end

  def test_include_absolute
    @interpreter.run_string '\\include "' + @path + '/minimal/main.sfp"'
  end

  def test_include_parse_error
    error = assert_raises SlideField::ParseError do
      @interpreter.run_string '\\include "test/parse_error.sfp"', @path
    end

    assert_match /\A\[input\] \[parse_error.sfp\] /, error.message
    refute_match /\\include/, error.message
  end

  def test_reparse
    @interpreter.run_file @path + '/minimal/main.sfp'

    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + '/minimal/main.sfp'
    end

    assert_equal "File already interpreted: '#{@path}/minimal/main.sfp'", error.message
  end

  def test_recursive_include
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + '/test/recursive_include.sfp'
    end

    assert_equal "[recursive_include.sfp] File already interpreted: '#{@path}/test/recursive_include.sfp'", error.message
  end

  def test_include_parent_folder
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + '/test/sub/include_parent.sfp'
    end

    assert_match /\A\[include_parent.sfp\] \[..\/unknown_object.sfp\] /, error.message

    error = assert_raises SlideField::ParseError do
      @interpreter.run_file @path + '/test/parse_error.sfp'
    end

    assert_match /\A\[parse_error.sfp\] /, error.message
  end

  def test_include_subfolder
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_file @path + '/test/include_sub.sfp'
    end

    assert_match /\A\[include_sub.sfp\] \[sub\/include_parent.sfp\] \[unknown_object.sfp\] /, error.message
  end

  def test_include_wrong_template
    error = assert_raises SlideField::InterpreterError do
      @interpreter.run_string '\\include "test/wrong_template.sfp"; \\&wrong_template', @path
    end

    assert_match /&wrong_template/, error.message
  end

  def test_include_unclosed_object
    assert_raises SlideField::ParseError do
      @interpreter.run_string '\\include "test/unclosed_object.sfp"', @path
    end
  end
end
