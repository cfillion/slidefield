SF::Object.define :include do
  set_variable :file, String
end

SF::Object.define :root do
  allow_children :layout, min: 1, max: 1
  allow_children :slide, min: 1
end

SF::Object.define :layout do
  set_variable :size, SF::Point
  set_variable :fullscreen, SF::Boolean.true
end

SF::Object.define :slide do
  allow_children :text
  allow_children :rect
  allow_children :image

  set_variable :position, SF::Point.zero
  set_variable :z_order, 0

  def loaded?
    @is_loaded
  end

  def preload(window)
    forward :preload, window
    @is_loaded = true
  end

  def activate
    forward :activate
  end

  def draw(animator)
    forward :draw, animator
  end

  def deactivate
    forward :deactivate
  end

  def unload
    forward :load
    @is_loaded = false
  end

  def forward(method, *args)
    @children.each {|c|
      c.send method, *args if c.respond_to? method
    }
  end
end

SF::Object.define :text do
  transparentize!

  set_variable :content, String
  set_variable :color, SF::Color.white
  set_variable :font, 'sans'
  set_variable :height, 20
  set_variable :width, 0
  set_variable :spacing, 0
  set_variable :align, 'left'

  def preload(window)
    @x, @y = value_of(:position).to_a
    @z = value_of :z_order
    @color = Gosu::Color.rgba *value_of(:color).to_a

    content = value_of :content
    font = value_of :font
    height = value_of :height
    spacing = value_of :spacing
    width = value_of :width
    align = value_of(:align).to_sym

    if font.include? '/'
      font = File.expand_path font, @obj.include_path
    end

    if width < 1
      # automatic width
      temp = Gosu::Image.from_text window, content, font, height
      width = temp.width
    end

    @image = Gosu::Image.from_text window, content, font, height, spacing, width, align
  end

  def draw(animator)
    tr = animator.transform self
    return if tr.skip_draw?

    x = @x + tr.x_offset
    y = @y + tr.y_offset

    color = @color.dup
    color.alpha = tr.opacity * @color.alpha

    @image.draw x, y, @z, tr.scale, tr.scale, color
  end

  def unload
    @image = nil
  end
end

SF::Object.define :rect do
  transparentize!

  set_variable :size, SF::Point
  set_variable :fill, SF::Color.white

  def preload(window)
    @window = window

    @x, @y = value_of(:position).to_a
    @z = value_of :z_order

    @width, @height = value_of(:size).to_a
    @fill = Gosu::Color.rgba *value_of(:fill).to_a
  end

  def draw(animator)
    tr = animator.transform self
    return if tr.skip_draw?

    x = @x + tr.x_offset
    y = @y + tr.y_offset

    width = @width * tr.scale
    height = @height * tr.scale

    color = @fill.dup
    color.alpha = tr.opacity * @fill.alpha

    @window.draw_quad(
      x, y, color,
      width + x, y, color,
      x, height + y, color,
      width + x, height + y, color,
      @z
    )
  end
end

SF::Object.define :image do
  transparentize!

  set_variable :source, String
  set_variable :size, SF::Point.zero
  set_variable :color, SF::Color.white

  def preload(window)
    @x, @y = value_of(:position).to_a
    @z = value_of :z_order
    @color = Gosu::Color.rgba *value_of(:color).to_a

    source = File.expand_path value_of(:source), @location.context.include_path
    width, height = value_of(:size).to_a

    @image = Gosu::Image.new window, source, true
    width = @image.width if 0 == width
    height = @image.height if 0 == height

    @x_scale = width / @image.width.to_f
    @y_scale = height / @image.height.to_f
  end

  def draw(animator)
    tr = animator.transform self
    return if tr.skip_draw?

    x = @x + tr.x_offset
    y = @y + tr.y_offset

    x_scale = tr.scale * @x_scale
    y_scale = tr.scale * @y_scale

    color = @color.dup
    color.alpha = tr.opacity * @color.alpha

    @image.draw x, y, @z, x_scale, y_scale, color
  end

  def on_unload
    @image = nil
  end
end
