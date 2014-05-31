module SlideField::ObjectRules
  class Include < Base
    def rules
      property :source, :string

      # don't call super
    end
  end
end
