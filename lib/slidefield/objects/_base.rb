module SlideField::ObjectRules
  class Base
    def rules
      child :include
    end
  end

  class SBase < Base
    def rules
      child :image
      child :rect
      child :song
      child :text

      super
    end
  end

  class GBase < SBase
    def rules
      variable :x, :number, 0
      variable :y, :number, 0
      variable :z, :number, 0

      super
    end
  end
end
