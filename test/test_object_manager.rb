require File.expand_path('../helper', __FILE__)

class TestObjectManager < MiniTest::Test
  def test_new
    window = nil

    obj1 = SlideField::ObjectData.new :slide, 'loc'
    obj2 = SlideField::ObjectData.new :text, 'loc'
    obj3 = SlideField::ObjectData.new :unknown, 'loc'

    klass1 = SlideField::ObjectManager::Slide
    klass2 = SlideField::ObjectManager::Text

    assert_instance_of klass1, SlideField::ObjectManager.new(obj1, window)
    assert_instance_of klass2, SlideField::ObjectManager.new(obj2, window)
    assert_nil SlideField::ObjectManager.new(obj3, window)
  end

  def test_slide_non_graphic_children
    obj1 = SlideField::ObjectData.new :slide, 'loc'
    obj2 = SlideField::ObjectData.new :unknown, 'loc'

    obj1 << obj2

    manager = SlideField::ObjectManager.new obj1, nil
    manager.load
  end
end
