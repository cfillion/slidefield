require File.expand_path '../helper', __FILE__

class TestRenderer < MiniTest::Test
  def test_invalid_root
    fake_obj = Struct.new(:type).new :non_root

    assert_raises ArgumentError do
      SF::Renderer.new fake_obj
    end
  end

  def test_layout
    root = SF::Object.new :root
    layout = SF::Object.new :layout
    layout.set_variable :size, SF::Point.new(4, 2)
    root.adopt layout

    renderer = SF::Renderer.new root
    assert_same layout.value_of(:size), renderer.size
  end
end
