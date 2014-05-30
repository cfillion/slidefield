module SlideField::ObjectRules
  class Base
    def rules
      child :include
      child :debug
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
      variable :position, :point, [0,0]
      variable :z_order, :integer, 0

      super
    end
  end
end
