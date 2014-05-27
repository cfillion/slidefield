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
        @children << SlideField::ObjectManager.new(c, @window)
        add_children_of c
      }
    end

    def forward(method)
      @children.each {|c| c.send method }
    end
  end
end
