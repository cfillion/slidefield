class SlideField::Interpreter
  attr_accessor :root

  def initialize
    @parser = SlideField::Parser.new
    @files = []
    @root = SlideField::ObjectData.new(:ROOT, 'line 0 char 0')
  end

  def run_file(path, parent_obj = nil)
    if @files.include? path
      raise SlideField::InterpreterError,
        "File already interpreted: '#{path}'"
    else
      @files << path
    end

    file = Pathname.new path

    begin
      input = file.read
    rescue => e
      raise SlideField::InterpreterError, e.message
    end

    include_path = file.dirname.to_s
    @rootpath = Pathname.new(include_path) if parent_obj.nil? || @rootpath.nil?
    context = file.relative_path_from(@rootpath).to_s

    run_string input, include_path, context, parent_obj
  end

  def run_string(input, include_path = '.', context = 'input', parent_obj = nil)
    include_path = File.absolute_path(include_path) + File::SEPARATOR

    object = parent_obj || @root
    object.include_path = include_path unless object.include_path
    object.context = context unless object.context

    close = parent_obj.nil?

    tree = @parser.parse input, reporter: Parslet::ErrorReporter::Deepest.new
    extract_tree tree, object, nil, include_path, context, close
  rescue Parslet::ParseFailed => error
    cause = error.cause
    reason = nil

    while cause
      reason = cause.to_s
      cause = cause.children.last
    end

    raise SlideField::ParseError, "[#{context}] #{reason}"
  rescue SlideField::Error => error
    raise error.class, "[#{context}] #{error.message}"
  end

  def extract_tree(tree, object, value_data = nil, child_path = nil, child_context = nil, close_object = true)
    rules = SlideField::ObjectRules[object.type]
    unless rules
      # the object was allowed but we don't know anything about it?!
      raise SlideField::InterpreterError,
        "Unsupported object '#{object.type}'"
    end

    if value_data
      # anonymous value
      val_type, value_t, value = extract_value value_data, object
      val_name = rules.matching_variables(val_type).first # guess variable name

      unless val_name
        raise SlideField::InterpreterError,
          "Unexpected '#{val_type}', expecting one of #{rules.known_variables_types} at #{get_loc value_t}"
      end

      object.set val_name, value, get_loc(value_t), val_type
    end

    tree.respond_to? :each and tree.each {|stmt|
      if stmt_data = stmt[:assignment]
        extract_variable rules, stmt_data, object
      elsif stmt_data = stmt[:object]
        extract_object rules, stmt_data, object, child_path, child_context
      else
        # we got strange data from the parser?!
        raise SlideField::InterpreterError,
          "Unsupported statement '#{stmt.keys.first}'"
      end
    }

    if close_object
      # finalize the object once all its content has been processed
      rules.required_variables.each {|name|
        unless object.get name
          raise SlideField::InterpreterError,
            "Missing property '#{name}' for object '#{object.type}' at #{object.loc}"
        end
      }

      rules.optional_variables.each {|name|
        next unless object.get(name).nil?

        default = rules.default_value name
        type = rules.type_of name

        object.set name, default, 'default', type
      }

      rules.required_children.each {|type|
        if object[type].empty?
          raise SlideField::InterpreterError,
            "Object '#{type}' not found in '#{object.type}' at #{object.loc}"
        end
      }
    end

    object
  end

  private
  def extract_variable(rules, stmt_data, object)
    var_name_t = stmt_data[:variable]
    var_name = var_name_t.to_sym

    operator_t = stmt_data[:operator]
    operator = operator_t.to_s
    
    var_type, var_value_t, var_value = extract_value stmt_data[:value], object

    case operator
    when '='
      if object.has? var_name
        raise SlideField::InterpreterError,
          "Variable '#{var_name}' is already defined at #{get_loc var_name_t}"
      end

      if valid_type = rules.type_of(var_name)
        if var_type != valid_type
          raise SlideField::InterpreterError,
            "Unexpected '#{var_type}', expecting '#{valid_type}' at #{get_loc var_value_t}"
        end
      end

      object.set var_name, var_value, get_loc(var_value_t), var_type
    when '+=', '-=', '*=', '/='
      origin_val = object.get var_name
      unless origin_val
        raise SlideField::InterpreterError,
          "Undefined variable '#{var_name}' at #{get_loc var_name_t}"
      end
      origin_type = object.var_type var_name

      method = operator[0]

      if var_type != origin_type
        raise SlideField::InterpreterError,
          "Unexpected '#{var_type}', expecting '#{origin_type}' at #{get_loc var_value_t}"
      end

      value = nil

      case origin_type
      when :integer
        value = origin_val.send method, var_value
      when :point, :color
        if origin_type != :color || ['+=', '-='].include?(operator)
          value = origin_val.collect.with_index {|v, i| v.send method, var_value[i] }

          if origin_type == :color
            # normalize
            value.collect! {|v|
              v = 0 if v < 0
              v = 255 if v > 255
              v
            }
          end
        end
      when :string
        case operator
        when '+='
          value = origin_val + var_value
        when '-='
          copy = origin_val.dup
          copy[var_value] = '' if copy[var_value]
          value = copy
        when '*='
          multiplier = var_value.to_i
          if multiplier < 1
            raise SlideField::InterpreterError,
              "Invalid string multiplier '#{var_value}', integer > 0 required at #{get_loc var_value_t}"
          end
          value = origin_val * multiplier
        end
      end

      unless value
        raise SlideField::InterpreterError,
          "Invalid operator '#{operator}' for type '#{origin_type}' at #{get_loc operator_t}"
      end

      object.set var_name, value, get_loc(var_value_t)
    else
      # the parser gave us strange data?!
      raise SlideField::InterpreterError,
        "Unsupported operator '#{operator}' at #{get_loc operator_t}"
    end
  rescue ZeroDivisionError
    raise SlideField::InterpreterError,
      "divided by zero at #{get_loc var_value_t}"
  end

  def extract_object(rules, stmt_data, object, include_path, context)
    type_t = stmt_data[:type]
    type = type_t.to_sym
    body = stmt_data[:body]

    unless rules.accepted_children.include?(type)
      raise SlideField::InterpreterError,
        "Unexpected object '#{type}', expecting one of #{rules.accepted_children} at #{get_loc type_t}"
    end

    child = SlideField::ObjectData.new type, get_loc(type_t)
    child.include_path = include_path
    child.context = context

    # enable inheritance
    child.parent = object

    extract_tree body, child || [], stmt_data[:value], include_path, context

    # process special objects
    if child.type == :include
      source = File.expand_path child.get(:source), include_path
      run_file source, object
    else
      object << child
    end
  end

  def get_loc(token)
    pos = token.line_and_column
    "line #{pos.first} char #{pos.last}"
  end

  def convert(type, value)
    case type
    when :identifier
      value
    when :integer
      value.to_i
    when :point
      value.to_s.split('x').collect &:to_i
    when :string
      escape_sequences = {
        'n'=>"\n"
      }

      value.to_s[1..-2].gsub(/\\(.)/) {
        escape_sequences[$1] || $1
      }
    when :color
      int = value.to_s[1..-1].hex

      r = (int >> 24) & 255
      g = (int >> 16) & 255
      b = (int >> 8) & 255
      a = (int) & 255
      [r, g, b, a]
    when :boolean
      value == ':true'
    else
      # the parser gave us strange data?!
      raise SlideField::InterpreterError, "Unsupported type '#{type}' at #{get_loc value}"
    end
  end

  def cast(token, type, value)
    id = token.to_sym
    case [type, id]
    when [:point, :x]
      type = :integer
      value = value[0]
    when [:point, :y]
      type = :integer
      value = value[1]
    else
      raise SlideField::InterpreterError,
        "Invalid cast '#{id}' for type '#{type}' at #{get_loc token}"
    end

    return type, value
  end

  def extract_value(data, object)
    cast_token = data.delete :cast
    value_data = data.first
    type = value_data[0]
    token = value_data[1]
    value = convert type, token

    if type == :identifier
      if id_value = object.get(value.to_sym)
        type = object.var_type(value.to_sym)
        value = id_value
      else
        raise SlideField::InterpreterError,
          "Undefined variable '#{value}' at #{get_loc token}"
      end
    end

    if cast_token
      type, value = cast cast_token, type, value
    end

    return type, token, value
  end
end
