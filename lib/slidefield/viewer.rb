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
      manager.activate
      @slides << manager
    }
  end

  def update
  end

  def draw
    @slides.first.draw
  end

  def button_down(id)
    case id
    when Gosu::KbEscape, 86, Gosu::KbQ
      close
    end
  end
end
