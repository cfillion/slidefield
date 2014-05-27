require File.expand_path('../helper', __FILE__)

class TestObjectManager < MiniTest::Test
  def test_new
    window = nil

    obj1 = SlideField::ObjectData.new :slide, 'loc'
    obj2 = SlideField::ObjectData.new :text, 'loc'

    klass1 = SlideField::ObjectManager::Slide
    klass2 = SlideField::ObjectManager::Text

    assert_instance_of klass1, SlideField::ObjectManager.new(obj1, window)
    assert_instance_of klass2, SlideField::ObjectManager.new(obj2, window)
  end
end
