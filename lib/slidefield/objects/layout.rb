module SlideField::ObjectRules
  class Layout < Base
    def rules
      variable :size, :point
      variable :fullscreen, :boolean, true
      super
    end
  end
end
