module SlideField::ObjectRules
  class Animation < SBase
    def rules
      property :name, :string
      property :duration, :integer, 400
      property :enter, :boolean, true
      property :leave, :boolean, true

      super
    end
  end
end
