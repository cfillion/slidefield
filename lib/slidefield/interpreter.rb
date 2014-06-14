class SlideField::Interpreter
  attr_accessor :root

  def initialize
    @files = []
    @parser = SlideField::Parser.new
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
    SlideField.debug "Parsing #{context}..."
    include_path = File.absolute_path(include_path) + File::SEPARATOR

    object = parent_obj || @root
    object.include_path = include_path unless object.include_path
    object.context = context unless object.context

    close = parent_obj.nil?

    begin
      tree = @parser.parse input, reporter: Parslet::ErrorReporter::Deepest.new
    rescue Parslet::ParseFailed => error
      cause = error.cause
      reason = nil

      while cause
        reason = cause.to_s
        cause = cause.children.last
      end

      raise SlideField::ParseError, reason
    end

    interpret_tree tree, object, include_path, context, close
  rescue SlideField::Error => error
    message = error.message

    if !message.start_with?('[') && message =~ /line (\d+) char (\d+)/
      line = $1.to_i - 1
      column = $2.to_i - 1

      if line > -1 && source = input.lines[line]
        excerpt = source.strip
        column -= source.index excerpt
        arrow = "#{"\x20" * column}^"

        message += "\n\t#{excerpt}\n\t#{arrow}"
      end
    end

    raise error.class, "[#{context}] #{message}"
  end

  def interpret_tree(tree, object, child_path = nil, child_context = nil, close_object = true)
    tree.respond_to? :each and tree.each {|stmt|
      if stmt_data = stmt[:assignment]
        interpret_assignment stmt_data, object
      elsif stmt_data = stmt[:object]
        interpret_object stmt_data, object, child_path, child_context
      else
        # we got strange data from the parser?!
        raise "Unsupported statement '#{stmt.keys.first}'"
      end
    }

    if close_object
      # finalize the object once all its content has been processed

      rules = object.rules
      rules.required_properties.each {|name|
        unless object.get name
          raise SlideField::InterpreterError,
            "Missing property '#{name}' for object '#{object.type}' at #{object.loc}"
        end
      }

      rules.optional_properties.each {|name|
        next unless object.get(name).nil?

        default = rules.default_value name
        type = rules.type_of_property name

        object.set name, default, 'default', type
      }

      rules.accepted_children.each {|type|
        min, max = rules.requirements_of_child type
        count = object[type].count

        if count < min
          raise SlideField::InterpreterError,
            "Object '#{object.type}' must have at least #{min} '#{type}', #{count} found at #{object.loc}"
        end

        if max > 0 && count > max
          raise SlideField::InterpreterError,
            "Object '#{object.type}' can not have more than #{max} '#{type}', #{count} found at #{object.loc}"
        end
      }
    end

    object
  end

  private
  def interpret_assignment(stmt_data, object)
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

      if valid_type = object.rules.type_of_property(var_name)
        if var_type != valid_type
          raise SlideField::InterpreterError,
            "Unexpected '#{var_type}', expecting '#{valid_type}' for property '#{var_name}' at #{get_loc var_value_t}"
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
          "Unexpected '#{var_type}', expecting '#{origin_type}' for variable or property '#{var_name}' at #{get_loc var_value_t}"
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
          copy[var_value] = '' while copy.include? var_value
          value = copy
        when '*='
          multiplier = var_value.to_i
          unless multiplier > 0
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
      raise "Unsupported operator '#{operator}' at #{get_loc operator_t}"
    end
  rescue ZeroDivisionError
    raise SlideField::InterpreterError,
      "divided by zero at #{get_loc var_value_t}"
  end

  def interpret_object(stmt_data, object, include_path, context)
    type_t = stmt_data[:type]
    type = type_t.to_sym
    body = stmt_data[:body] || []

    anon_values = []
    anon_values << stmt_data[:value] if stmt_data[:value]

    template_t = stmt_data[:template]
    template = stmt_data

    while template[:template]
      template = object.get type
      unless template
        raise SlideField::InterpreterError,
          "Undefined variable '#{type}' at #{get_loc type_t}"
      end

      unless :object == tpl_type = object.var_type(type)
        raise SlideField::InterpreterError,
          "Unexpected '#{tpl_type}', expecting 'object' at #{get_loc type_t}"
      end

      type = template[:type].to_sym

      if template[:value]
        tpl_value = rebind_tokens template[:value], template_t
        anon_values << tpl_value
      end

      if template[:body]
        tpl_body = rebind_tokens template[:body], template_t
        body += tpl_body
      end
    end

    unless object.rules.accepted_children.include?(type)
      raise SlideField::InterpreterError,
        "Unexpected object '#{type}', expecting one of #{object.rules.accepted_children.sort} at #{get_loc type_t}"
    end

    child = SlideField::ObjectData.new type, get_loc(type_t)
    child.include_path = include_path
    child.context = context
    child.parent = object # enable variable inheritance

    unless child.rules
      # the object was allowed but we don't know anything about it?!
      raise "Unsupported object '#{child.type}'"
    end

    anon_values.each {|value_data|
      interpret_anon_value value_data, child
    }
    interpret_tree body, child || [], include_path, context

    # process special objects
    case child.type
    when :include
      source = File.expand_path child.get(:source), include_path
      run_file source, object
    when :debug
      debug_infos = {
        :type=>child.var_type(:thing),
        :value=>child.get(:thing)
      }

      puts "DEBUG in #{child.context} at #{child.loc}:"
      ap debug_infos
      puts
    else
      object << child
    end
  end

  def interpret_anon_value(value_data, object)
    val_type, value_t, value = extract_value value_data, object
    var_name = object.rules.matching_properties(val_type).first # guess variable name

    unless var_name
      raise SlideField::InterpreterError,
        "Unexpected '#{val_type}', expecting one of #{object.rules.properties_types} at #{get_loc value_t}"
    end

    if object.has? var_name
      raise SlideField::InterpreterError,
        "Variable '#{var_name}' is already defined at #{get_loc value_t}"
    end

    object.set var_name, value, get_loc(value_t), val_type
  end

  def get_loc(token)
    pos = token.line_and_column
    "line #{pos.first} char #{pos.last}"
  end

  def extract_value(data, object)
    filters = data.delete :filters
    value_data = data.first
    type = value_data[0]
    token = value_data[1]
    value = convert type, token

    if type == :identifier
      if id_value = object.get(value.to_sym)
        type = object.var_type value.to_sym
        value = id_value
      else
        raise SlideField::InterpreterError,
          "Undefined variable '#{value}' at #{get_loc token}"
      end
    elsif type == :object
      token = token[:type]
    end

    filters.reverse_each {|filter_token|
      type, value = filter filter_token, type, value
    }

    return type, token, value
  end

  def convert(type, token)
    case type
    when :identifier, :object
      token
    when :integer
      token.to_i
    when :point
      token.to_s.split('x').collect &:to_i
    when :string
      escape_sequences = {
        'n'=>"\n"
      }

      token.to_s[1..-2].gsub(/\\(.)/) {
        escape_sequences[$1] || $1
      }
    when :color
      int = token.to_s[1..-1].hex

      r = (int >> 24) & 255
      g = (int >> 16) & 255
      b = (int >> 8) & 255
      a = (int) & 255
      [r, g, b, a]
    when :boolean
      token == ':true'
    else
      # the parser gave us strange data?!
      raise "Unsupported type '#{type}' at #{get_loc token}"
    end
  end

  def filter(token, type, value)
    name_t = token[:name]
    name = name_t.to_sym

    case [type, name]
    when [:point, :x]
      type = :integer
      value = value[0]
    when [:point, :y]
      type = :integer
      value = value[1]
    when [:integer, :x]
      type = :point
      value = [value, 0]
    when [:integer, :y]
      type = :point
      value = [0, value]
    when [:string, :lines]
      type = :integer
      value = value.lines.count
    else
      raise SlideField::InterpreterError,
        "Invalid filter '#{name}' for type '#{type}' at #{get_loc name_t}"
    end

    return type, value
  end

  def rebind_tokens(tree, dest)
    case tree
    when Array
      tree.collect {|h| rebind_tokens h, dest }
    when Hash
      tree = tree.dup
      tree.each {|k, v| tree[k] = rebind_tokens v, dest }
    when Parslet::Slice
      Parslet::Slice.new dest.position, tree.str, dest.line_cache
    end
  end
end
