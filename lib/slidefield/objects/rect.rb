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
    def on_load
      @x, @y = @obj.get :position
      @z = @obj.get :z_order

      @width, @height = @obj.get :size
      @fill = Gosu::Color.rgba *@obj.get(:fill)
    end

    def on_draw(animator)
      tr = animator.transform @obj
      return if tr.skip_draw?

      x = @x + tr.x_offset
      y = @y + tr.y_offset

      width = @width * tr.scale
      height = @height * tr.scale

      color = @fill.dup
      color.alpha = tr.opacity * @fill.alpha

      @window.draw_quad(
        x, y, color,
        width + x, y, color,
        x, height + y, color,
        width + x, height + y, color,
        @z
      )
    end
  end
end
