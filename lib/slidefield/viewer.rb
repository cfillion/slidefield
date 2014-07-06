class SlideField::Viewer < Gosu::Window
  # preloader settings
  LOAD_AROUND = 4
  LOAD_DELAY = 1000

  def initialize(project)
    layout = project[:layout].first
    layout_size = layout.get :size
    fullscreen = layout.get :fullscreen

    super *layout_size, fullscreen

    @time = 0
    @animator = SlideField::Animator.new layout_size

    @slides = []
    project[:slide].each {|slide_data|
      manager = SlideField::ObjectManager.new slide_data, self
      @slides << manager
    }

    change_slide 0
  end

  def update
    now = Gosu::milliseconds
    if now - @time > LOAD_DELAY && @need_reload
      smart_loader
      @need_reload = false
    end

    return unless needs_redraw?
    @time = now
    @need_reload = true
  end

  def draw
    # animate the previous slide
    if @previous && @animator.need_redraw?
      @animator.frame @time, false, @forward do
        @slides[@previous].draw @animator
      end
    end

    @animator.frame @time, true, @forward do
      @slides[@current].draw @animator
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

    # can't wait the preloader
    unless @slides[@current].loaded?
      @slides[@current].load
    end

    @slides[@current].activate
    @animator.reset
  end

  private
  def smart_loader
    ahead = LOAD_AROUND / 2
    behind = -ahead

    @slides.each_with_index {|manager, index|
      rel_index = index - @current
      keep = rel_index >= behind && rel_index <= ahead

      if keep && !manager.loaded?
        manager.load
      elsif !keep && manager.loaded?
        manager.unload
      end
    }

    # really unload resources
    GC.start
  end
end
