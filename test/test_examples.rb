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
end
