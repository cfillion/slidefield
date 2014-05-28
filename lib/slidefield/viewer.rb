class SlideField::Viewer < Gosu::Window
  def initialize(project)
    layout = project[:layout]
    size = layout.first.get :output

    super *size, false

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
