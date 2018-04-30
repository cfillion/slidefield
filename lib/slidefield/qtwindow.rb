class SlideField::QtWindow < Qt::Widget
  FRAMERATE = 60

  def initialize(files, options)
    @files, @options = files, options

    super nil, Qt::DialogType

    next_file

    Qt::Timer.singleShot 1, self, SLOT("start()")
    show
  end

  def next_file(slide = SF::Renderer::FIRST_SLIDE)
    until @files.empty?
      file = @files.shift
      interpreter = SlideField::Interpreter.new

      if '-' == file
        interpreter.run_string STDIN.read
      else
        path = File.absolute_path file
        interpreter.run_file path
      end

      next if interpreter.failed? || @options.include?(:check)

      @renderer = SF::Renderer.new interpreter.root
      jump_to slide
      break true
    end
  end

  def update_title
    setWindowTitle '%s (%d/%d) — SlideField v%s' % [
      @renderer.label,
      @renderer.current_index + 1, @renderer.slide_count,
      SF::VERSION
    ]
  end

  def jump_to(slide)
    @renderer.jump_to slide
    update_title
  end

  def start
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

      jump_to SF::Renderer::NEXT_SLIDE
    when Qt::Key_Backspace, Qt::Key_Left, Qt::Key_Up, Qt::Key_Minus
      jump_to SF::Renderer::PREV_SLIDE
    when Qt::Key_Home
      jump_to SF::Renderer::FIRST_SLIDE
    when Qt::Key_End
      jump_to SF::Renderer::LAST_SLIDE
    end
  end

  def closeEvent(event)
    event.ignore if next_file
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
