module SlideField::ObjectRules
  class Image < GBase
    def rules
      variable :source, :string
      super
    end
  end
end
