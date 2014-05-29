module SlideField::ObjectRules
  class Layout < Base
    def rules
      variable :output, :point
      variable :size, :point, [0,0]
      variable :fullscreen, :boolean, true
      super
    end
  end
end
