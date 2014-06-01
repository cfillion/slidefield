module SlideField::ObjectRules
  class Animation < GBase
    def rules
      property :name, :string
      property :duration, :integer, 400

      super
    end
  end
end
