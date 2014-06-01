class SlideField::Viewer < Gosu::Window
  def initialize(project)
    layout = project[:layout].first
    layout_size = layout.get :size
    fullscreen = layout.get :fullscreen

    super *layout_size, fullscreen

    @animator = SlideField::Animator.new layout_size

    @slides = []
    project[:slide].each {|slide_data|
      manager = SlideField::ObjectManager.new slide_data, self
      manager.load
      @slides << manager
    }

    change_slide 0
  end

  def update
    @time = Gosu::milliseconds
  end

  def draw
    @animator.frame @time, true, @forward do
      @slides[@current].draw @animator
    end

    if @animator.need_redraw?
      @animator.frame @time, false, @forward do
        @slides[@previous].draw @animator if @previous
      end
    end
  end

  def needs_redraw?
    @animator.need_redraw?
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

      change_slide @current+1
    when
      Gosu::KbBackspace,
      Gosu::KbLeft,
      Gosu::KbUp,
      Gosu::KbPageUp,
      Gosu::KbNumpadSubtract

      change_slide @current-1
    when Gosu::KbEscape, Gosu::KbQ
      close
    end
  end

  private
  def change_slide(index)
    return if @current == index || index < 0 || index > @slides.length-1

    @previous = @current
    @current = index

    if @previous
      @slides[@previous].deactivate
      @forward = @previous < @current
    else
      @forward = true
    end

    @slides[@current].activate

    @animator.reset
  end
end
