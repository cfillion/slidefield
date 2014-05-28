class SlideField::Viewer < Gosu::Window
  def initialize(project)
    layout = project[:layout].first

    fullscreen = layout.get :fullscreen
    layout_size = layout.get :size
    output_size = layout.get :output
    layout_size = output_size if layout_size == [0, 0]

    @x_scale = output_size[0] / layout_size[0].to_f
    @y_scale = output_size[1] / layout_size[1].to_f

    super *output_size, fullscreen

    @slides = []
    project[:slide].each {|slide_data|
      manager = SlideField::ObjectManager.new slide_data, self
      manager.load
      @slides << manager
    }

    change_slide 0
  end

  def update
  end

  def draw
    scale @x_scale, @y_scale do
      @current.draw
    end
  end

  def button_down(id)
    case id
    when Gosu::KbHome
      change_slide 0
    when Gosu::KbEnd
      change_slide @slides.length-1
    when
      Gosu::KbReturn,
      Gosu::KbSpace,
      Gosu::KbTab,
      Gosu::KbRight,
      Gosu::KbDown,
      Gosu::KbPageDown,
      Gosu::KbNumpadAdd

      change_slide @index+1
    when
      Gosu::KbBackspace,
      Gosu::KbLeft,
      Gosu::KbUp,
      Gosu::KbPageUp,
      Gosu::KbNumpadSubtract

      change_slide @index-1
    when Gosu::KbEscape, 86, Gosu::KbQ
      close
    end
  end

  private
  def change_slide(index)
    return if index < 0 || index > @slides.length-1
    @index = index

    @current.deactivate if @current
    @current = @slides[index]
    @current.activate
  end
end
