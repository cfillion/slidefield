class SlideField::Variable < SlideField::Token
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
      :integer
    when String
      :string
    when SF::Boolean
      :boolean
    when SF::Color
      :color
    when SF::Point
      :point
    when SF::Template
      :template
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

    super
  end

  def compatible_with?(other)
    other = SF::Variable[other]

    if @type.is_a?(Symbol) # validate object
      other.value.is_a?(SF::Object) && other.value.type == @type
    else
      other.value.class == @type
    end
  end

  def type
    self.class.type_of @value
  end

  def apply(operator, other)
    operator = SF::Token[operator]
    method = operator.to_s[0]

    if @value.respond_to? method
      new_value = @value.send method, other.value
      self.class.new new_value, other.location
    else
      !error_at operator.location,
        "invalid operator '%s=' for type '%s'" % [method, type]
    end
  rescue => e
    !error_at(other.location,
      case e
      when ArgumentError
        'invalid operation (%s)' % e.message
      when TypeError
        "incompatible operands ('%s' %s '%s')" %
          [type, method, other.type]
      when ZeroDivisionError
        'divison by zero (evaluating %p %s %p)' %
          [@value, method, other.value]
      when SF::ColorOutOfBoundsError
        'color is out of bounds (evaluating %p %s %p)' %
          [@value, method, other.value]
      else
        raise
      end
    )
  end

  def filter(filter)
    filter = SF::Token[filter]
    filter_method = "filter_#{filter}"

    if @value.respond_to? filter_method
      new_value = value.send filter_method

      self.class.new new_value, @location
    else
      !error_at filter.location,
        "unknown filter '%s' for type '%s'" %
        [filter, type]
    end
  end
end
