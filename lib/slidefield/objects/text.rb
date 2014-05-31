module SlideField::ObjectRules
  class Text < GBase
    def rules
      property :content, :string
      property :color, :color, [255, 255, 255, 255]
      property :font, :string, "sans"
      property :height, :integer, 20
      property :width, :integer, 0
      property :spacing, :integer, 0
      property :align, :string, "left"

      super
    end
  end
end

module SlideField::ObjectManager
  class Text < Base
    def load
      @x, @y = @obj.get :position
      @z = @obj.get :z_order

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
