class SlideField::Interpreter
  include SF::Doctor

  attr_accessor :root

  EFAIL = Object.new.freeze

  ESCAPE_SEQUENCES = {
    'n'=>"\n"
  }.freeze

  MAX_LEVEL = 50

  def initialize
    @parser = SF::Parser.new
    @reporter = Parslet::ErrorReporter::Deepest.new

    @root = SF::Object.new :root
    @context_level = 0

    @failed = false
  end

  def run_file(path)
    catch(EFAIL) { internal_run_file path }
  end

  def run_string(input)
    catch(EFAIL) { internal_run_string input }
  end

  def failed?
    @failed
  end

private
  def internal_run_file(path)
    file = Pathname.new path

    unless file.exist?
      error_at last_location,
        'no such file or directory - %s' % file

      failure
    end

    begin
      input = file.read
    rescue
      error_at last_location,
        'unreadable file - %s' % file

      failure
    end

    include_path = file.dirname
    rootpath = @rootpath || include_path
    label = file.relative_path_from(rootpath).to_s

    run input, label, include_path.to_s
  end

  def internal_run_string(input)
    run input, 'input', Dir.pwd
  end

  def run(input, label, include_path)
    object = @context ? @context.object : @root
    context = SF::Context.new label, include_path, object, input

    with(context) {
      tree = parse input
      enter_in tree
    }

    if !failed? && @context.nil?
      failure unless @root.valid?
    end
  end

  def with(context)
    context_backup = @context

    @context = context.freeze
    @context_level += 1

    if @context_level > MAX_LEVEL
      error_at last_location,
        'context level exceeded maximum depth of %i' % MAX_LEVEL

      failure
    end

    @rootpath = Pathname.new @context.include_path if @rootpath.nil?

    yield
  ensure
    @context = context_backup
    @context_level -= 1
  end

  def parse(input)
    @parser.parse input, reporter: @reporter
  rescue Parslet::ParseFailed => error
    cause = error.cause

    while next_cause = cause.children.last
      cause = next_cause
    end

    message = Array(cause.message).map { |o| 
      o.respond_to?(:to_slice) ? o.str.inspect : o.to_s
    }.join

    message[0] = message[0].downcase

    location = location_at *cause.source.line_and_column(cause.pos)
    error_at location, message

    failure
  end

  def enter_in(tree)
    catch EFAIL do
      tree.respond_to? :each and tree.each {|stmt|
        eval_statement *stmt.to_a[0]
      }
    end
  end

  def eval_statement(type, tokens)
    case type
    when :assignment
      eval_assignment tokens
    when :object
      add_object eval_object(tokens)
    when :template
      eval_template tokens
    end
  end

  def eval_assignment(tokens)
    var_name_t = tokens[:variable]
    var_name = var_name_t.to_sym

    operator_t = tokens[:operator]
    operator = operator_t.to_s

    if tokens.has_key? :value
      right_location, right_value = eval_value tokens[:value]
    else
      right_location = locate var_name_t
      right_value = SF::Template.new @context, tokens[:statements]
    end

    if operator == '='
      new_value = right_value
    else
      left_var = @context.object.get_variable var_name

      begin
        new_value = left_var.value.send operator[0], right_value
      rescue NoMethodError
        error_at locate(operator_t),
          "invalid operator '%s' for type '%s'" %
          [operator, left_var.type]

        failure
      rescue ArgumentError => e
        error_at right_location,
          'invalid operation (%s)' % e.message

        failure
      rescue TypeError
        error_at right_location,
          "incompatible operands ('%s' %s '%s')" %
          [left_var.type, operator[0], SF::Variable.type_of(right_value)]

        failure
      rescue ZeroDivisionError
        error_at right_location,
          'divison by zero (evaluating %p %s %p)' %
          [left_var.value, operator[0], right_value]

        failure
      rescue SF::ColorOutOfBoundsError
        error_at right_location,
          'color is out of bounds (evaluating %p %s %p)' %
          [left_var.value, operator[0], right_value]

        failure
      end
    end

    @context.object.set_variable var_name, new_value, right_location
  rescue SF::IncompatibleValueError => e
    error_at right_location, e.message

    failure
  end

  def eval_value(tokens)
    tokens = tokens.clone
    filters = tokens.delete :filters

    type, data_t = tokens.to_a[0]
    value = transform_value type, data_t

    filters.reverse_each {|a|
      filter_t = a[:name]
      filter_method = "filter_#{filter_t}"

      if value.respond_to? filter_method
        value = value.send filter_method
      else
        error_at locate(filter_t),
          "unknown filter '%s' for type '%s'" %
          [filter_t, SF::Variable.type_of(value)]

        failure
      end
    }
    
    location = type == :object ? value.location : locate(data_t)
    [location, value]
  end

  def transform_value(type, token)
    case type
    when :identifier
      resolve_identifier token
    when :integer
      token.to_i
    when :point
      SF::Point.new *token.to_s.split('x').map(&:to_i)
    when :string
      token.to_s[1..-2].gsub(/\\(.)/) {
        ESCAPE_SEQUENCES[$1] || $1
      }
    when :color
      int = token.to_s[1..-1].hex

      r = (int >> 24) & 255
      g = (int >> 16) & 255
      b = (int >> 8) & 255
      a = (int) & 255

      SF::Color.new r, g, b, a
    when :boolean
      SF::Boolean.new token == ':true'
    when :object
      eval_object token, true
    end
  end

  def resolve_identifier(token)
    begin
      value = @context.object.value_of token.to_sym
    rescue SF::VariableNotFoundError => e
      error_at locate(token), e.message

      failure
    end

    if value.nil?
      error_at locate(token),
        "use of uninitialized variable '%s'" % token

      failure
    end

    value
  end

  def eval_object(tokens, is_inline = false)
    type_t = tokens[:type]
    type = type_t.to_sym

    location = locate type_t

    begin
      object = SF::Object.new type, location
    rescue SF::UndefinedObjectError => e
      failure
    end

    if is_inline
      # prevent this object from being adopted with the subobjects
      object.block_auto_adopt!
    end

    if value_t = tokens[:value]
      assign_value value_t, object
    end

    if subtree = tokens[:statements]
      context = @context.dup
      context.object = object

      with(context) { enter_in subtree }
    end

    failure unless object.valid?

    object
  end

  def assign_value(token, object)
    value_location, new_value = eval_value token

    begin
      var_name = object.guess_variable new_value
    rescue SF::IncompatibleValueError, SF::AmbiguousValueError => e
      error_at value_location, e.message

      failure
    end

    object.set_variable var_name, new_value, value_location
  end

  def add_object(object)
    if object.type == :include
      path = File.expand_path object.value_of(:file), @context.include_path
      internal_run_file path
      return
    end

    begin
      object.auto_adopt
    rescue SF::UnauthorizedChildError
      failure
    end
  end

  def eval_template(tokens)
    name_t = tokens[:name]
    name = name_t.to_sym

    location = locate name_t

    begin
      variable = @context.object.get_variable name
    rescue SF::VariableNotFoundError => e
      error_at location, e.message

      failure
    end

    template = variable.value

    case template
    when SF::Template
      context = template.context.dup
      context.object = @context.object

      with(context) { enter_in template.statements }
    when SF::Object
      add_object template.copy(location)
    else
      error_at location,
        'not a template or an object (see definition at %s)' %
        variable.location

      failure
    end
  end

  def failure
    @failed = true

    throw EFAIL
  end

  def locate(token)
    location_at *token.line_and_column
  end

  def location_at(line, column)
    @last_location = SF::Location.new @context, line, column
  end

  def last_location
    @last_location ||= SF::Location.new
  end
end
