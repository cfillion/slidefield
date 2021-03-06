class SlideField::Animator
  def initialize(layout_size)
    @layout_size = layout_size
    reset
  end

  def need_redraw?
    @animations.each {|k,v| return true if v.enabled }
    @animations.empty?
  end

  def reset
    @animations = {}
  end

  def frame(*args)
    struct = Struct.new :time, :current?, :forward?
    @frame = struct.new *args
    yield
    @frame = nil
  end

  def transform(obj)
    raise "Can not animate outside a frame" unless @frame

    tr_struct = Struct.new :skip_draw?, :x_offset, :y_offset, :scale, :opacity
    tr = tr_struct.new false, 0, 0, 1.0, 1.0

    anim = animation_for obj.ancestor(:animation)

    # no animation
    return tr if anim.nil?

    # direction disabled
    cur_direction = @frame.forward? ? @frame.current? : !@frame.current?
    dir_enabled = cur_direction ? anim.enter : anim.leave
    anim.enabled = false unless dir_enabled

    elapsed = @frame.time - anim.start_time
    position = elapsed / anim.duration
    anim.enabled = false if position > 1.0

    # animation finished
    unless anim.enabled
      tr[:skip_draw?] = !@frame.current? # don't draw the previous slide anymore
      return tr
    end

    width, height = @layout_size

    case anim.name
    when "fade"
      if @frame.current?
        tr.opacity = position
      else
        tr.opacity = 1.0 - position
      end
    when "slide right"
      tr.x_offset = slide_offset position, width, false
    when "slide left"
      tr.x_offset = slide_offset position, width, true
    when "slide down"
      tr.y_offset = slide_offset position, height, false
    when "slide up"
      tr.y_offset = slide_offset position, height, true
    when "zoom"
      if @frame.current?
        tr.scale = position
      else
        tr.scale = 1.0 - position
      end
    else
      # the validator has missed ?!
      # TODO: validate at interpret time
      raise SlideField::RuntimeError,
        "Unsupported animation '#{anim.name}'"
    end

    tr
  end

  private
  def animation_for(data)
    return @animations[data] if @animations.has_key? data

    anim_struct = Struct.new :enabled, :start_time, :name, :duration, :enter, :leave
    anim = anim_struct.new false, 0.0, '', 0, true, true

    if data
      anim.enabled = true
      anim.start_time = @frame.time.to_f
      anim.name = data.get :name
      anim.duration = data.get :duration
      anim.enter = data.get :enter
      anim.leave = data.get :leave
    end

    @animations[data] = anim
  end

  def slide_offset(position, size, inverse)
    inverse = !inverse unless @frame.forward?

    offset = size * position
    offset -= size if @frame.current?
    offset = 0 - offset if inverse
    offset
  end
end
