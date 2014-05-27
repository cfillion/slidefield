module SlideField::ObjectRules
  class Base
    def rules
      child :include
    end
  end

  class GBase < Base
    def rules
      variable :x, :number, 0
      variable :y, :number, 0
      variable :z, :number, 0

      child :text
      child :image
      super
    end
  end
end
