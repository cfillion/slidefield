module SlideField::ObjectRules
  class Include < Base
    def rules
      variable :source, :string
      # don't call super here
      # include should not be allowed inside another include
    end
  end
end
