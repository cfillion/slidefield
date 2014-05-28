class SlideField::ObjectData
  attr_reader :type, :loc, :children
  attr_accessor :context, :include_path, :parent

  def initialize(type, loc)
    @type = type
    @loc = loc
    @variables = {}
    @children = []
  end

  def has?(var)
    @variables.has_key? var
  end

  def set(var, val, loc = nil, type = nil)
    loc ||= var_loc var
    type ||= var_type var

    @variables[var] = [type, val, loc]
  end

  def get(var)
    if has? var
      @variables[var][1]
    elsif parent
      parent.get var
    end
  end

  def var_type(var)
    if has? var
      @variables[var][0] 
    elsif parent
      parent.var_type var
    end
  end

  def var_loc(var)
    if has? var
      @variables[var][2] 
    elsif parent
      parent.var_loc var
    end
  end

  def <<(child)
    child.parent = self
    @children << child
  end

  def [](selector)
    @children.select {|o| o.type == selector }
  end

  def context_string
    array = [@context]
    parent = @parent
    while parent
      array.unshift parent.context unless array.first == parent.context
      parent = parent.parent
    end
    "[#{array.join '] ['}]"
  end
end
