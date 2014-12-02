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
    @children_rules = {}
    @hooks = {}
    @variables = {}

    @finalize = true
    @passthrough = false

    unless @@initializers.has_key? type
      raise SF::UndefinedObjectError, error_at(@location,
        "unknown object name '%s'" % type
      )
    end

    prepare
  end

  def inspect
    '\\%s@%s' % [@type, @location]
  end

  def copy(location = nil)
    newone = self.class.new @type, location
    newone.variables = @variables
    newone.children = @children

    newone
  end

  def passthrough?; @passthrough end
  def set_passthrough(val = true); @passthrough = !!val end

  def root?
    @context_parent.nil?
  end

  def has_variable?(name)
    @variables.has_key? name
  end

  def set_variable(name, variable, location = nil)
    name = name.to_sym
    variable = SF::Variable[variable, location]

    if compatible? name, variable
      @variables[name] = variable
    else
      !error_at variable.location,
        "incompatible assignation ('%s' to '%s')" %
        [@variables[name].type, variable.type]
    end
  end

  def get_variable(name)
    name = SF::Token[name]
    key = name.to_sym

    if !has_variable?(key)
      !error_at name.location, "undefined variable '%s'" % key
    elsif @variables[key].value.nil?
      !error_at name.location, "use of uninitialized variable '%s'" % name
    else
      @variables[key]
    end
  end

  def value_of(name)
    variable = get_variable(name)
    variable ? variable.value : variable
  end

  def guess_variable(var)
    var = SF::Variable[var]

    matches = @variables.select {|k,v|
      v.location.native? && v.value.nil? && v.compatible_with?(var)
    }.keys

    case matches.length
    when 0
      !error_at var.location,
        "object '%s' has no uninitialized variable compatible with '%s'" %
        [@type, var.type]
    when 1
      matches.first
    else
      !error_at var.location, 'value is ambiguous'
    end
  end

  def allow_children(type, min: 0, max: Infinity)
    @children_rules[type] = Range.new(min, max)
  end

  def knows?(child)
    @children_rules.has_key? child.type
  end

  def block_finalize!
    @finalize = false
  end

  def adopt(object)
    unless knows? object
      error_at object.location,
        "object '%s' cannot have '%s'" % [@type, object.type]

      return false
    end
    
    maximum = @children_rules[object.type].max
    if count(object.type) >= maximum
      error_at object.location,
        "object '%s' cannot have more than %d '%s'" %
        [@type, maximum, object.type]

      return false
    end

    object.parent = self
    @children << object

    true
  end

  def finalize
    return true if !@finalize || @parent

    if @context_parent && !@context_parent.root?
      @context_parent.finalize or return false
    end

    if parent = find_a_parent
      parent.adopt self
      true
    else
      !error_at @location,
        "object '%s' is not allowed in this context" % @type
    end
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

  def validate
    validate_children && validate_variables
  end

  def set_hook(event, &block)
    @hooks[event] = block
  end

  def call_hook(event, *args)
    @hooks[event].call *args if @hooks.has_key? event
  end

private
  def prepare
    instance_eval &@@initializers[type]

    not root? and @context_parent.variables.each {|name, var|
      @variables[name] = var if compatible? name, var
    }
  end

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

  def find_a_parent
    next_try = @context_parent

    catch(:found_parent) {
      while next_try
        throw :found_parent, next_try if next_try.knows? self
        next_try = next_try.passthrough? && next_try.context_parent
      end
    }
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
