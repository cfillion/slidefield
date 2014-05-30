module SlideField::ObjectRules
  class Include < Base
    def rules
      variable :source, :string

      # don't call super here
    end
  end
end
