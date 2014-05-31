module SlideField::ObjectRules
  class Image < GBase
    def rules
      property :source, :string
      property :size, :point, [0,0]

      super
    end
  end
end

module SlideField::ObjectManager
  class Image < Base
    def load
      @x, @y = @obj.get :position
      @z = @obj.get :z_order

      source = File.expand_path @obj.get(:source), @obj.include_path
      width, height = @obj.get :size

      @image = Gosu::Image.new @window, source, true
      width = @image.width if 0 == width
      height = @image.height if 0 == height

      @x_scale = width / @image.width.to_f
      @y_scale = height / @image.height.to_f
    end

    def draw
      @window.scale @x_scale, @y_scale do
        @image.draw @x, @y, @z
      end
    end
  end
end
