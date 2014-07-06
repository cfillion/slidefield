module SlideField::ObjectRules
  class Image < GBase
    def rules
      property :source, :string
      property :size, :point, [0,0]
      property :color, :color, [255, 255, 255, 255]

      super
    end
  end
end

module SlideField::ObjectManager
  class Image < Base
    def on_load
      @x, @y = @obj.get :position
      @z = @obj.get :z_order
      @color = Gosu::Color.rgba *@obj.get(:color)

      source = File.expand_path @obj.get(:source), @obj.include_path
      width, height = @obj.get :size

      @image = Gosu::Image.new @window, source, true
      width = @image.width if 0 == width
      height = @image.height if 0 == height

      @x_scale = width / @image.width.to_f
      @y_scale = height / @image.height.to_f
    end

    def on_draw(animator)
      tr = animator.transform @obj
      return if tr.skip_draw?

      x = @x + tr.x_offset
      y = @y + tr.y_offset

      x_scale = tr.scale * @x_scale
      y_scale = tr.scale * @y_scale

      color = @color.dup
      color.alpha = tr.opacity * @color.alpha

      @image.draw x, y, @z, x_scale, y_scale, color
    end

    def on_unload
      @image = nil
    end
  end
end
