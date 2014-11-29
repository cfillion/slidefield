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
    @last_location = SF::Location.new
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
      error_at @last_location, 'no such file or directory - %s' % file
      failure
    end

    begin
      input = file.read
    rescue
      error_at @last_location, 'unreadable file - %s' % file
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
      error_at @last_location,
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

    line, column = *cause.source.line_and_column(cause.pos)
    location = SF::Location.new @context, line, column
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
    var_name = tokenize tokens[:variable]
    operator = tokenize tokens[:operator]

    if value = tokens[:value]
      right_location, right_value = eval_value value
    elsif stmts_t = tokens[:statements]
      right_location = var_name.location
      right_value = SF::Template.new @context, stmts_t
    end

    right_var = SF::Variable.new right_value, right_location

    if operator != '='
      left_var = @context.object.get_variable(var_name) or failure
      right_var = left_var.apply(operator, right_var) or failure
    end

    @context.object.set_variable var_name, right_var or failure
  end

  def eval_value(tokens)
    tokens = tokens.clone
    filters = tokens.delete :filters

    type, data = tokens.to_a[0]
    value = transform_value type, data

    filters.reverse_each {|t|
      filter = tokenize t[:name]
      filter_method = "filter_#{filter}"

      if value.respond_to? filter_method
        value = value.send filter_method
      else
        error_at filter.location,
          "unknown filter '%s' for type '%s'" %
          [filter, SF::Variable.type_of(value)]

        failure
      end
    }
    
    if type == :object
      [value.location, value]
    else
      [tokenize(data).location, value]
    end
  end

  def transform_value(type, token)
    case type
    when :identifier
      @context.object.value_of token.to_sym or failure
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
      eval_object token, inline: true
    end
  end

  def eval_object(tokens, inline: false)
    type = tokenize tokens[:type]

    begin
      object = SF::Object.new type.to_sym, type.location
    rescue SF::UndefinedObjectError
      failure
    end

    if inline
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
    variable = SF::Variable.new new_value, value_location # TODO: remove

    var_name = object.guess_variable(variable) or failure
    object.set_variable var_name, variable
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
    name = tokenize tokens[:name]

    variable = @context.object.get_variable(name) or failure
    template = variable.value

    case template
    when SF::Template
      context = template.context.dup
      context.object = @context.object

      with(context) { enter_in template.statements }
    when SF::Object
      add_object template.copy(name.location)
    else
      error_at name.location,
        'not a template or an object (see definition at %s)' %
        variable.location

      failure
    end
  end

  def failure
    @failed = true

    throw EFAIL
  end

  def tokenize(slice)
    @last_location = SF::Location.new @context, *slice.line_and_column

    SF::Token.new slice, @last_location
  end
end
