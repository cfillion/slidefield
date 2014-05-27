module SlideField::ObjectRules
  class Text < GBase
    def rules
      variable :content, :string
      variable :color, :color, [255, 255, 255, 255]
      variable :font, :string, "sans"
      variable :height, :number, 20
      super
    end
  end
end

module SlideField::ObjectManager
  class Text < Base
    def load
      @x = @obj.get :x
      @y = @obj.get :y
      @z = @obj.get :z

      content = @obj.get :content
      @color = Gosu::Color.rgba *@obj.get(:color)
      font = @obj.get :font
      height = @obj.get :height

      @image = Gosu::Image.from_text @window, content, font, height
    end

    def draw
      @image.draw @x, @y, @z, 1, 1, @color
    end
  end
end
