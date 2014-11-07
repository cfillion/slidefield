require File.expand_path '../helper', __FILE__

class TestExamples < MiniTest::Test
  def setup
    @interpreter = SlideField::Interpreter.new
    @examples_path = File.expand_path '../examples', __dir__
  end

  def test_minimal
    file_path = File.join(@examples_path, 'minimal/main.sfp')

    @interpreter.run_file file_path

    assert_equal File.dirname(file_path), @interpreter.root.include_path
    assert_equal File.dirname(file_path), @interpreter.root[:layout].first.include_path
    assert_equal File.basename(file_path), @interpreter.root.context
    assert_equal File.basename(file_path), @interpreter.root[:layout].first.context
  end

  def test_complete
    file_path = File.join @examples_path, 'complete/main.sfp'
    mountains_path = File.join @examples_path, 'complete/slides/mountains.sfi'

    @interpreter.run_file file_path

    assert_equal File.dirname(mountains_path), @interpreter.root[:slide].first.include_path
    assert_equal File.dirname(mountains_path), @interpreter.root[:slide].first.children.first.include_path
    assert_equal 'slides/mountains.sfi', @interpreter.root[:slide].first.context
    assert_equal 'slides/mountains.sfi', @interpreter.root[:slide].first.children.first.context

    assert_equal File.dirname(file_path), @interpreter.root.include_path
    assert_equal 'main.sfp', @interpreter.root.context
  end
end
