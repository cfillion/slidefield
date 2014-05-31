module SlideField::ObjectRules
  class Layout < Base
    def rules
      property :size, :point
      property :fullscreen, :boolean, true

      super
    end
  end
end
