SF::Object.define :group do
  set_passthrough
end

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
  allow_children :group
  allow_children :rect
  allow_children :text
  allow_children :image
  allow_children :audio

  default_anim = SF::Object.new :animation
  default_anim.set_variable :name, 'cut'

  set_variable :position, SF::Point.zero
  set_variable :enter, default_anim
  set_variable :leave, default_anim
end

SF::Object.define :rect do
  set_passthrough

  set_variable :size, SF::Point
  set_variable :fill, SF::Color.white

  set_hook :paint do |painter, global_cache|
    unless cache = global_cache[self]
      brush = Qt::Brush.new Qt::Color.new *value_of(:fill)
      rect = Qt::Rect.new *value_of(:position), *value_of(:size)

      cache = global_cache[self] = OpenStruct.new
      cache.brush = brush
      cache.rect = rect
    end

    painter.setPen Qt::NoPen
    painter.setBrush cache.brush
    painter.drawRect cache.rect
  end
end

SF::Object.define :text do
  set_passthrough

  set_variable :content, String
  set_variable :color, SF::Color.white
  set_variable :font, 'sans'
  set_variable :height, 20
  set_variable :width, 0
  set_variable :spacing, 0
  set_variable :align, 'left'

  set_hook :paint do |painter, global_cache|
    unless cache = global_cache[self]
      content = value_of(:content).gsub /\n/, '<br>'
      fontfamily = value_of(:font)

      if fontfamily.include? '/'
        path = File.expand_path fontfamily, @location.include_path

        if global_cache[path]
          fontfamily = global_cache[path]
        else
          id = Qt::FontDatabase.addApplicationFont path

          if id > -1
            fontfamily = Qt::FontDatabase.applicationFontFamilies(id).first
            global_cache[path] = fontfamily
          else
            warning_at get_variable(:font).location,
              'unable to load %s' % path
          end
        end
      end

      option = Qt::TextOption.new
      # option.setWrapMode Qt::TextOption::NoWrap

      case value_of(:align).to_sym
      when :center
        option.setAlignment Qt::AlignHCenter
      when :right
        option.setAlignment Qt::AlignRight
      when :justify
        option.setAlignment Qt::AlignJustify
      end

      static = Qt::StaticText.new content
      static.setTextFormat Qt::RichText
      static.setTextOption option

      font = Qt::Font.new fontfamily
      font.setPixelSize value_of(:height)

      fm = Qt::FontMetrics.new font
      font.setPixelSize value_of(:height) - (fm.height - value_of(:height))

      if value_of(:width) > 0
        width = value_of(:width)
      else
        width = fm.width content
      end

      static.setTextWidth width

      color = Qt::Color.new *value_of(:color)

      pixmap = Qt::Pixmap.new width, width # TODO: height
      pixmap.fill Qt::Color.new Qt::transparent
      pixpainter = Qt::Painter.new pixmap
      pixpainter.setFont font
      pixpainter.setPen color
      pixpainter.drawStaticText 0, 0, static
      pixpainter.end

      cache = global_cache[self] = OpenStruct.new
      cache.pixmap = pixmap
    end

    painter.drawPixmap *value_of(:position),
      cache.pixmap.size.width, cache.pixmap.size.height, cache.pixmap
  end
end

SF::Object.define :image do
  set_passthrough

  set_variable :source, String
  set_variable :size, SF::Point.zero
  set_variable :color, SF::Color.white

  set_hook :paint do |painter, cache|
    position = value_of :position
    file = File.expand_path value_of(:source), @location.include_path

    pixmap = (cache[file] ||= Qt::Pixmap.new file)

    if value_of(:size) == SF::Point.zero
      size = [pixmap.width, pixmap.height]
    else
      size = value_of :size
    end

    painter.drawPixmap *value_of(:position), *size, pixmap
  end
end

SF::Object.define :audio do
  set_variable :source, String
  set_variable :volume, 100
  set_variable :loop, SF::Boolean.false
  set_variable :auto_play, SF::Boolean.true

  set_hook :activate do |global|
    unless cache = global[self]
      file = File.expand_path value_of(:source), @location.include_path

      channel = -1
      while channel == -1
        SDL::Mixer.AllocateChannels SDL::Mixer.AllocateChannels(-1) + 1
        channel = SDL::Mixer.GroupAvailable -1
      end

      cache = global[self] = OpenStruct.new
      cache.channel = channel
      cache.sound = SDL::Mixer.LoadWAV file
      cache.repeats = value_of(:loop).to_bool ? -1 : 0
      cache.started = false
    end

    call_hook :play, global if value_of(:auto_play).to_bool
  end

  set_hook :play do |global|
    cache = global[self]

    next false if cache.started

    SDL::Mixer.Volume cache.channel, (SDL::Mixer::MAX_VOLUME * (value_of(:volume).fdiv 100)).to_i
    SDL::Mixer.PlayChannelTimed(cache.channel, cache.sound, cache.repeats, -1)

    cache.started = true
  end

  set_hook :deactivate do |global|
    cache = global[self]
    SDL::Mixer.HaltChannel cache.channel
    cache.started = false
  end
end

SF::Object.define :animation do
  set_passthrough

  set_variable :name, String
  set_variable :duration, 400
end

