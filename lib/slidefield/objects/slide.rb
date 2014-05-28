module SlideField::ObjectRules
  class Slide < GBase; end
end

module SlideField::ObjectManager
  class Slide < Base
    def load
      @children = []
      add_children_of @obj

      forward :load
    end

    def activate
      forward :activate
    end

    def draw
      forward :draw
    end

    def deactivate
      forward :deactivate
    end

    def unload
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

    def forward(event)
      @children.each {|c| c.execute event }
    end
  end
end
