class SlideField::Viewer < Gosu::Window
  def initialize(project)
    layout = project[:layout].first
    layout_size = layout.get :size
    fullscreen = layout.get :fullscreen

    super *layout_size, fullscreen

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
    @current.draw
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
