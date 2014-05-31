module SlideField::ObjectRules
  class Rect < GBase
    def rules
      property :size, :point
      property :fill, :color, [255, 255, 255, 255]

      super
    end
  end
end

module SlideField::ObjectManager
  class Rect < Base
    def load
      @x, @y = @obj.get :position
      @z = @obj.get :z_order

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
