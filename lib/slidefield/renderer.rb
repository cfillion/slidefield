class SlideField::Renderer
  attr_reader :label, :size

  FIRST_SLIDE = Object.new.freeze
  NEXT_SLIDE = Object.new.freeze
  PREV_SLIDE = Object.new.freeze
  LAST_SLIDE = Object.new.freeze

  def initialize(root)
    raise ArgumentError unless root.type == :root

    @label = root.location.label

    layout = root.first_child :layout
    @size = layout.value_of :size

    @cache = {}
    @forward = true

    @elements = []
    root.children(:slide).each {|slide|
      @elements << slide.children.reverse
    }

    @animator = SF::Animator.new @size
    @timer = Qt::ElapsedTimer.new
    @timer.start
  end

  def jump_to(index)
    case index
    when FIRST_SLIDE
      index = 0
      @in_extra = false
    when NEXT_SLIDE
      if @elements[@slide_index].any? { |obj| obj.call_hook :play, @cache }
        @in_extra = true
        return false
      end

      index = @slide_index + 1
      @in_extra = false
    when PREV_SLIDE
      if @in_extra
        index = @slide_index
      else
        index = @slide_index - 1
      end
    when LAST_SLIDE
      index = @elements.count - 1
      @in_extra = false
    end

    return if index < 0 || index >= @elements.count

    @previous_index, @slide_index = @slide_index, index

    if @previous_index
      @elements[@previous_index].each { |obj| obj.call_hook :deactivate, @cache }
      @forward = @previous_index < index
    else
      @forward = true
    end

    @elements[@slide_index].each { |obj| obj.call_hook :activate, @cache }
    if @in_extra
      @in_extra = false
    else
      @animator.reset
    end
  end

  def next_frame?
    @animator.need_redraw?
  end

  def paint(painter)
    return unless @slide_index

    time = @timer.elapsed

    previous = @previous_index ? @elements[@previous_index].clone : []
    current = @elements[@slide_index].clone

    while !previous.empty? || !current.empty?
      obj = previous.shift

      @animator.frame time, false, @forward do
        paint_element obj, painter
      end if obj

      obj = current.shift

      @animator.frame time, true, @forward do
        paint_element obj, painter
      end if obj
    end
  end

  def paint_element(obj, painter)
    painter.save
    @animator.transform painter, obj
    obj.call_hook :paint, painter, @cache
    painter.restore
  end
end
