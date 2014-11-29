class SlideField::Variable
  attr_reader :value, :location

  VALUE_CLASSES = [
    Fixnum,
    String,
    SF::Boolean,
    SF::Color,
    SF::Point,
    SF::Template,
    # SF::Object is a special case
  ].freeze

  def self.type_of(value)
    case value
    when Fixnum
      'integer'
    when String
      'string'
    when SF::Boolean
      'boolean'
    when SF::Color
      'color'
    when SF::Point
      'point'
    when SF::Template
      'template'
    when SF::Object
      "\\#{value.type}"
    end
  end

  def initialize(value, location = nil)
    if value.is_a?(Class) || value.is_a?(Symbol)
      @type, value = value, nil
    else
      @type = value.is_a?(SF::Object) ? value.type : value.class
    end

    unless @type.is_a?(Symbol) || VALUE_CLASSES.include?(@type)
      raise SF::ForeignValueError
    end

    location ||= SF::Location.new
    @value, @location = value.freeze, location
  end

  def compatible_with?(other_value)
    if @type.is_a?(Symbol) # validate object
      other_value.is_a?(SF::Object) && other_value.type == @type
    else
      other_value.class == @type
    end
  end

  def type
    self.class.type_of @value
  end
end