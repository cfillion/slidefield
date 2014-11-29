class SlideField::Object
  include SF::Doctor

  Infinity = Float::INFINITY

  @@initializers = {}

  def self.define(type, &block)
    @@initializers[type] = block
  end

  attr_reader :type, :location

  def initialize(type, location = nil)
    @type = type

    @location = location || SF::Location.new
    @context_parent = @location.context.object

    @children = []
    @variables = {}

    @auto_adopt = true
    @children_rules = {}
    @opaque = true

    unless @@initializers.has_key? type
      raise SF::UndefinedObjectError, error_at(@location,
        "unknown object name '%s'" % type
      )
    end

    instance_eval &@@initializers[type]

    not root? and @context_parent.variables.each {|name, var|
      @variables[name] = var if compatible? name, var.value
    }
  end

  def copy(location = nil)
    newone = self.class.new @type, location
    newone.variables = @variables
    newone.children = @children

    newone
  end

  def opaque?; @opaque end
  def transparentize!; @opaque = false end
  def opacify!; @opaque = true end

  def root?
    @context_parent.nil?
  end

  def has_variable?(name)
    @variables.has_key? name
  end

  def set_variable(name, value, location = nil)
    unless compatible? name, value
      raise SF::IncompatibleValueError,
        "incompatible assignation ('%s' to '%s')" %
        [@variables[name].type, SF::Variable.type_of(value)]
    end

    @variables[name] = SF::Variable.new value, location
  end

  def get_variable(name)
    unless has_variable? name
      raise SF::VariableNotFoundError,
        "undefined variable '%s'" % name
    end

    @variables[name]
  end

  def value_of(name)
    get_variable(name).value
  end

  def guess_variable(value)
    matches = @variables.select {|k,v|
      v.location.native? && v.value.nil? && v.compatible_with?(value)
    }.keys

    case matches.length
    when 0
      raise SF::IncompatibleValueError,
        "object '%s' has no uninitialized variable compatible with '%s'" %
        [@type, SF::Variable.type_of(value)]
    when 1
      matches.first
    else
      raise SF::AmbiguousValueError,
        'value is ambiguous'
    end
  end

  def allow_children(type, min: 0, max: Infinity)
    @children_rules[type] = Range.new(min, max)
  end

  def knows?(child)
    @children_rules.has_key? child.type
  end

  def block_auto_adopt!
    @auto_adopt = false
  end

  def adopt(object)
    unless knows? object
      raise SF::UnauthorizedChildError, error_at(object.location,
        "object '%s' cannot have '%s'" % [@type, object.type]
      )
    end
    
    maximum = @children_rules[object.type].max
    if count(object.type) >= maximum
      raise SF::UnauthorizedChildError, error_at(object.location,
        "object '%s' cannot have more than %d '%s'" %
        [@type, maximum, object.type]
      )
    end

    object.parent = self

    @children << object
  end

  def auto_adopt
    return unless @auto_adopt

    if @context_parent && !@context_parent.root?
      @context_parent.auto_adopt 
    end

    parent = catch(:found_parent) {
      next_try = @context_parent

      while next_try
        throw :found_parent, next_try if next_try.knows? self
        next_try = next_try.opaque? ? nil : next_try.context_parent
      end
    }

    unless parent
      raise SF::UnauthorizedChildError, error_at(@location,
        "object '%s' is not allowed in this context" % @type
      )
    end

    parent.adopt self
    block_auto_adopt!
  end

  def children(type = nil)
    if type
      @children.select {|c| c.type == type }
    else
      @children.clone
    end
  end

  def first_child(type)
    children(type).first
  end

  def count(type = nil)
    children(type).count
  end

  def valid?
    validate_children && validate_variables
  end

  def inspect
    '\\%s@%s' % [@type, @location]
  end

private
  def compatible?(name, other_value)
    !has_variable?(name) || @variables[name].compatible_with?(other_value)
  end

  def validate_children
    @children_rules.select {|type, range|
      size = count type

      # the upper limit case is handled in the parent's #adopt method

      if size < range.min
        error_at @location,
          "object '%s' must have at least %d '%s', got %d" %
          [@type, range.min, type, size]
      end
    }.empty?
  end

  def validate_variables
    nil_vars = @variables.select {|name, var|
      if var.value.nil?
        warning_at var.location, "'%s' is uninitialized" % name
      end
    }

    return true if nil_vars.empty?

    !error_at @location,
      "object '%s' has one or more uninitialized variables" % @type
  end

protected
  attr_reader :context_parent
  attr_accessor :variables
  attr_writer :children

  def parent=(new_parent)
    raise SF::AlreadyAdoptedError if @parent

    @parent = new_parent
  end
end
