require File.expand_path '../helper', __FILE__

module SlideField::ObjectManager
  class CatchTest < Base
    def on_load(what)
      raise what
    end
  end
end

class TestObjectManager < MiniTest::Test
  def test_new
    window = nil

    obj1 = SlideField::ObjectData.new :slide, 'loc'
    obj2 = SlideField::ObjectData.new :text, 'loc'
    obj3 = SlideField::ObjectData.new :unknown, 'loc'

    klass1 = SlideField::ObjectManager::Slide
    klass2 = SlideField::ObjectManager::Text

    assert_instance_of klass1, man1 = SlideField::ObjectManager.new(obj1, window)
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

  def test_catch
    obj = SlideField::ObjectData.new :catchTest, 'loc'
    obj.context = 'context'

    manager = SlideField::ObjectManager.new obj, nil
    error = assert_raises SlideField::RuntimeError do
      manager.load 'error message'
    end

    assert_equal "[context] An error occured while executing the 'load' event on the object 'catchTest' at loc:\n\t(RuntimeError) error message", error.message
  end
end
