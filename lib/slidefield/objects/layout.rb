module SlideField::ObjectRules
  class Layout < Base
    def rules
      variable :output, :size
      variable :size, :size, [0, 0]
      variable :fullscreen, :boolean, true
      super
    end
  end
end
