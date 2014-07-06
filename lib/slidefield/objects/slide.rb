module SlideField::ObjectRules
  class Slide < SBase; end
end

module SlideField::ObjectManager
  class Slide < Base
    def loaded?
      @is_loaded
    end

    def on_load
      @is_loaded = true
      @children = []
      add_children_of @obj

      forward :load
    end

    def on_activate
      forward :activate
    end

    def on_draw(animator)
      forward :draw, animator
    end

    def on_deactivate
      forward :deactivate
    end

    def on_unload
      @is_loaded = false
      forward :unload
    end

    private
    def add_children_of(obj)
      obj.children.each {|c|
        manager = SlideField::ObjectManager.new c, @window
        @children << manager if manager
        add_children_of c
      }
    end

    def forward(event, *args)
      @children.each {|c| c.execute event, *args }
    end
  end
end
