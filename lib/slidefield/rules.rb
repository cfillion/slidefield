module SlideField::ObjectRules
  class Base
    def rules
      child :include
    end
  end

  class ROOT < Base
    def rules
      child :layout, true
      child :slide, true
      super
    end
  end

  class Layout < Base
    def rules
      variable :output, :size
      super
    end
  end

  class Include < Base
    def rules
      variable :source, :string
      # don't call super here
      # include should not be allowed inside another include
    end
  end

  class Slide < Base
    def rules
      child :text
      super
    end
  end

  class GBase < Slide
    def rules
      variable :x, :number, 0
      variable :y, :number, 0
      variable :z, :number, 0
      super
    end
  end

  class Text < GBase
    def rules
      variable :content, :string
      variable :color, :color
      variable :font_family, :string, "sans"
      variable :font_size, :number, 20
      super
    end
  end
end
