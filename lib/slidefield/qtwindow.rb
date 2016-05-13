class SlideField::QtWindow < Qt::Widget
  FRAMERATE = 60

  def initialize(renderer)
    @renderer = renderer

    super nil, Qt::DialogType

    update_title

    Qt::Timer.singleShot 1, self, SLOT("start()")
    show
  end

  def update_title
    setWindowTitle '%s (%d/%d) — SlideField v%s' % [
      @renderer.label,
      @renderer.current_index + 1, @renderer.slide_count,
      SF::VERSION
    ]
  end

  def start
    @renderer.jump_to SF::Renderer::FIRST_SLIDE

    @timer = Qt::Timer.new
    @timer.setInterval 1000 / FRAMERATE
    connect @timer, SIGNAL('timeout()'), self, SLOT("update_if_required()")
    @timer.start
  end
  slots :start

  def sizeHint
    Qt::Size.new *@renderer.size
  end

  def update_if_required
    update if @renderer.next_frame?
  end

  slots :update_if_required

  def paintEvent(a)
    painter = Qt::Painter.new self
    painter.setRenderHint Qt::Painter::Antialiasing | Qt::Painter::SmoothPixmapTransform

    # fill the background
    painter.fillRect rect(), Qt::black

    # scale the content
    zoom, offset = zoom_and_offset
    painter.translate Qt::Point.new *offset
    painter.scale zoom, zoom

    # prevent overflows
    painter.setClipRect Qt::Rect.new 0, 0, *@renderer.size

    # go!
    @renderer.paint painter

    painter.end
  end

  def changeEvent(event)
    return unless event.type == Qt::Event::WindowStateChange

    cursor = isFullScreen ? Qt::BlankCursor : Qt::ArrowCursor
    Qt::Application.setOverrideCursor Qt::Cursor.new cursor
  end

  def keyPressEvent(event)
    case event.key
    when Qt::Key_Escape, Qt::Key_Q
      close
    when Qt::Key_F
      setWindowState windowState ^ Qt::WindowFullScreen
    when
      Qt::Key_Return,
      Qt::Key_Tab,
      Qt::Key_Space,
      Qt::Key_Right,
      Qt::Key_Down,
      Qt::Key_Plus

      @renderer.jump_to SF::Renderer::NEXT_SLIDE
      update_title
    when Qt::Key_Backspace, Qt::Key_Left, Qt::Key_Up, Qt::Key_Minus
      @renderer.jump_to SF::Renderer::PREV_SLIDE
      update_title
    when Qt::Key_Home
      @renderer.jump_to SF::Renderer::FIRST_SLIDE
      update_title
    when Qt::Key_End
      @renderer.jump_to SF::Renderer::LAST_SLIDE
      update_title
    end
  end

private
  def zoom_and_offset
    dest_w, dest_h = *@renderer.size

    scale_x = width.fdiv dest_w
    scale_y = height.fdiv dest_h
    zoom = [scale_x, scale_y].min

    real_w = dest_w * zoom
    real_h = dest_h * zoom

    offset_x = (width - real_w) / 2
    offset_y = (height - real_h) / 2

    [zoom, [offset_x, offset_y]]
  end
end