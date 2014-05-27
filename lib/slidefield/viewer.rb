class SlideField::Viewer < Gosu::Window
  def initialize(project)
    layout = project[:layout]
    size = layout.first.get :output

    super *size, false

    @artist = SlideField::Artist.new self

    @slides = project[:slide]
  end

  def update
  end

  def draw
    @artist.draw @slides.first
  end

  def button_down(id)
    case id
    when Gosu::KbEscape, 86, Gosu::KbQ
      close
    end
  end
end
