module SlideField::ObjectRules
  class Text < GBase
    def rules
      variable :content, :string
      variable :color, :color, [255, 255, 255, 255]
      variable :font, :string, "sans"
      variable :height, :number, 20
      variable :width, :number, 0
      variable :spacing, :number, 0
      variable :align, :string, "left"

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
      spacing = @obj.get :spacing
      width = @obj.get :width
      align = @obj.get(:align).to_sym

      if width < 1
        # automatic width
        temp = Gosu::Image.from_text @window, content, font, height
        width = temp.width
      end

      @image = Gosu::Image.from_text @window, content, font, height, spacing, width, align
    end

    def draw
      @image.draw @x, @y, @z, 1, 1, @color
    end
  end
end
