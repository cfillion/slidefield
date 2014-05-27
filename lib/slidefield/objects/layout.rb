module SlideField::ObjectRules
  class Layout < Base
    def rules
      variable :output, :size
      super
    end
  end
end
