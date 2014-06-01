module SlideField::ObjectRules
  class Base
    def rules
      child :include
      child :debug
    end
  end

  class SBase < Base
    def rules
      child :animation
      child :image
      child :rect
      child :song
      child :text

      super
    end
  end

  class GBase < SBase
    def rules
      property :position, :point, [0,0]
      property :z_order, :integer, 0

      super
    end
  end
end
