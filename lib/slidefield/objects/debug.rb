module SlideField::ObjectRules
  class Debug < Base
    def rules
      property :thing, :integer
      property :thing, :string
      property :thing, :point
      property :thing, :color
      property :thing, :boolean
      property :thing, :object

      # don't call super
    end
  end
end
