module SlideField::ObjectRules
  class ROOT < Base
    def rules
      child :layout, true
      child :slide, true
      super
    end
  end
end
