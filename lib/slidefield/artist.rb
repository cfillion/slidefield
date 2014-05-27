class SlideField::Artist
  def initialize(window)
    @window = window
    @fonts = {}
  end

  def draw(obj)
    send "draw_#{obj.type}", obj
    obj.children.each {|c| draw c }
  end

  def draw_slide(obj)
  end

  def draw_text(obj)
    x = obj.get :x
    y = obj.get :y
    z = obj.get :z

    content = obj.get :content
    color = Gosu::Color.rgba *obj.get(:color)
    family = obj.get :font_family
    size = obj.get :font_size

    font_key = "#{family}/#{size}"
    font = if @fonts.has_key? font_key
      @fonts[font_key]
    else
      @fonts[font_key] = Gosu::Font.new(@window, family, size)
    end

    font.draw content, x, y, z, 1.0, 1.0, color
  end
end
