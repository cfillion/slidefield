class SlideField::Variable
  include SF::Doctor

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
      raise SF::ForeignValueError,
        "cannot store '%s' in a variable" % @type
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

  def apply(operator, other)
    new_value = @value.send operator, other.value

    self.class.new new_value, other.location
  rescue NoMethodError
    !error_at other.location,
      "invalid operator '%s=' for type '%s'" %
      [operator, type]
  rescue ArgumentError => e
    !error_at other.location,
      'invalid operation (%s)' % e.message
  rescue TypeError
    !error_at other.location,
      "incompatible operands ('%s' %s '%s')" %
      [type, operator, other.type]
  rescue ZeroDivisionError
    !error_at other.location,
      'divison by zero (evaluating %p %s %p)' %
      [@value, operator, other.value]
  rescue SF::ColorOutOfBoundsError
    !error_at other.location,
      'color is out of bounds (evaluating %p %s %p)' %
      [@value, operator, other.value]
  end
end
