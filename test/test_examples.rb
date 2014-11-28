require File.expand_path '../helper', __FILE__

class TestExamples < MiniTest::Test
  def setup
    @interpreter = SlideField::Interpreter.new
    @examples_path = File.expand_path '../examples', __dir__
  end

  def test_minimal
    path = File.join @examples_path, 'minimal/main.sfp'
    @interpreter.run_file path

    assert_empty @interpreter.diagnostics
    refute @interpreter.failed?
  end

  def test_complete
    path = File.join @examples_path, 'complete/main.sfp'
    @interpreter.run_file path

    assert_empty @interpreter.diagnostics
    refute @interpreter.failed?
  end
end
