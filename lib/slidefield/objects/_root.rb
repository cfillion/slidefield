module SlideField::ObjectRules
  class ROOT < Base
    def rules
      child :layout, 1, 1
      child :slide, 1

      super
    end
  end
end
