module SlideField::ObjectRules
  class Debug < Base
    def rules
      # hack
      # `thing = 10x10` or anything but an integer will raise an error
      # however `\debug 10x10` works as expected

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
