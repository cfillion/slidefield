module SlideField::ObjectRules
  class Debug < Base
    def rules
      variable :thing, :integer
      variable :thing, :string
      variable :thing, :point
      variable :thing, :color
      variable :thing, :boolean
      variable :thing, :object
    end
  end
end
