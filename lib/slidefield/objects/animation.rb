module SlideField::ObjectRules
  class Animation < SBase
    def rules
      property :name, :string
      property :duration, :integer, 400

      super
    end
  end
end
