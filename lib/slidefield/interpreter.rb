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

    input = file.read
    include_path = file.dirname.to_s
    @rootpath = Pathname.new(include_path) if parent_obj.nil? || @rootpath.nil?
    context = file.relative_path_from(@rootpath).to_s

    run_string input, include_path, context, parent_obj
  end

  def run_string(input, include_path = '.', context = 'input', parent_obj = nil)
    tree = @parser.parse input, reporter: Parslet::ErrorReporter::Deepest.new
    include_path = File.absolute_path(include_path) + File::SEPARATOR
    object = parent_obj || @root
    validate = parent_obj.nil?

    extract_tree tree, object, include_path, nil, validate
  rescue Parslet::ParseFailed => error
    raise SlideField::ParseError, "[#{context}] #{error.cause.ascii_tree}"
  rescue SlideField::Error => error
    raise error.class, "[#{context}] #{error.message}"
  end

  def extract_tree(tree, object, include_path = nil, value_data = nil, close_object = true)
    rules = SlideField::ObjectRules[object.type]
    unless rules
      raise SlideField::InterpreterError,
        "Unsupported object '#{object.type}'"
    end

    if value_data
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
        extract_object rules, stmt_data, object, include_path
      else
        raise SlideField::InterpreterError,
          "Unsupported statement '#{stmt.keys.first}'"
      end
    }

    if close_object
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
    when '+=', '-='
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

      new_value =
      if origin_type == :size || origin_type == :color
        origin_val.map.with_index {|v, i| v.send method, var_value[i] }
      elsif origin_type == :string && operator == '-='
        copy = origin_val.dup
        copy[var_value] = '' if copy[var_value]
        copy
      else
        origin_val.send method, var_value
      end

      object.set var_name, new_value, get_loc(var_value_t)
    else
      raise SlideField::InterpreterError,
        "Unsupported operator '#{operator}' at #{get_loc operator_t}"
    end
  end

  def extract_object(rules, stmt_data, object, include_path)
    type_t = stmt_data[:type]
    type = type_t.to_sym
    body = stmt_data[:body]

    unless rules.accepted_children.include?(type)
      raise SlideField::InterpreterError,
        "Unexpected object '#{type}', expecting one of #{rules.accepted_children} at #{get_loc type_t}"
    end

    child = SlideField::ObjectData.new type, get_loc(type_t)
    child.parent = object # bind variables
    extract_tree body, child || [], include_path, stmt_data[:value]

    # process special commands
    if child.type == :include
      begin
        source = File.expand_path child.get(:source), include_path
        run_file source, object
      rescue Errno::ENOENT
        raise SlideField::InterpreterError,
          "No such file or directory: '#{source}'"
      end
    else
      object << child
    end
  end

  def get_loc(token)
    pos = token.line_and_column
    "line #{pos.first} char #{pos.last}"
  end

  def convert(value, type)
    case type
    when :identifier
      value.to_s
    when :number
      value.to_i
    when :size
      value.to_s.split('x').map(&:to_i)
    when :string
      escape_sequences = {
        'n'=>"\n"
      }

      value.to_s[1..-2].gsub(/\\(.)/) {
        escape_sequences[$1] || $1
      }
    when :color
      string = value.to_s
      string[0] = ''
      int = string.hex

      r = (int >> 24) & 255
      g = (int >> 16) & 255
      b = (int >> 8) & 255
      a = (int) & 255
      [r, g, b, a]
    else
      raise SlideField::InterpreterError, "Unsupported type '#{type}'"
    end
  end

  def extract_value(data, object)
    value_data = data.first
    type = value_data[0]
    token = value_data[1]
    value = convert token, type

    if type == :identifier
      if id_value = object.get(value.to_sym)
        type = object.var_type(value.to_sym)
        value = id_value
      else
        raise SlideField::InterpreterError,
          "Undefined variable '#{value}' at #{get_loc token}"
      end
    end

    return type, token, value
  end
end
