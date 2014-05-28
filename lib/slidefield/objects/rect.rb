module SlideField::ObjectRules
  class Rect < GBase
    def rules
      variable :size, :size
      variable :fill, :color, [255, 255, 255, 255]

      super
    end
  end
end

module SlideField::ObjectManager
  class Rect < Base
    def load
      @x = @obj.get :x
      @y = @obj.get :y
      @z = @obj.get :z

      @width, @height = @obj.get :size
      @fill = Gosu::Color.rgba *@obj.get(:fill)
    end

    def draw
      @window.draw_quad(
        @x, @y, @fill,
        @width + @x, @y, @fill,
        @x, @height + @y, @fill,
        @width + @x, @height + @y, @fill,
        @z
      )
    end
  end
end
