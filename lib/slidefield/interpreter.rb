class SlideField::Interpreter
  include SF::Doctor

  attr_accessor :root

  EFAIL = Object.new.freeze

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

  def eval_statement(type, slices)
    case type
    when :assignment
      eval_assignment slices
    when :object
      add_object eval_object(slices)
    when :template
      eval_template slices
    end
  end

  def eval_assignment(slices)
    var_name = tokenize slices[:variable]
    operator = tokenize slices[:operator]

    if value = slices[:value]
      right = eval_value value
    elsif stmts_t = slices[:statements]
      value = SF::Template.new @context, stmts_t
      right = SF::Variable.new value, var_name.location
    end

    if operator != '='
      left = @context.object.get_variable(var_name) or failure
      right = left.apply(operator, right) or failure
    end

    @context.object.set_variable var_name, right or failure
  end

  def eval_value(slices)
    slices = slices.clone
    filters = slices.delete :filters

    type, slice = slices.to_a[0]
    value = transform_value type, slice

    var = SF::Variable.new value,
      type == :object ? value.location : tokenize(slice).location

    filters.reverse_each {|t|
      filter = tokenize t[:name]
      var = var.filter(filter) or failure
    }

    var
  end

  def transform_value(type, slice)
    case type
    when :identifier
      @context.object.value_of tokenize(slice) or failure
    when :object
      eval_object slice, inline: true
    else
      klass = SF::Variable::KNOWN_TYPES[type]
      klass.from_slice slice
    end
  end

  def eval_object(slices, inline: false)
    type = tokenize slices[:type]

    begin
      object = SF::Object.new type.to_sym, type.location
    rescue SF::UndefinedObjectError
      failure
    end

    if inline
      # prevent this object from being adopted with the subobjects
      object.block_auto_adopt!
    end

    if value = slices[:value]
      variable = eval_value value
      var_name = object.guess_variable(variable) or failure
      object.set_variable var_name, variable
    end

    if subtree = slices[:statements]
      context = @context.dup
      context.object = object

      with(context) { enter_in subtree }
    end

    failure unless object.valid?

    object
  end

  def add_object(object)
    if object.type == :include
      path = File.expand_path object.value_of(:file), @context.include_path
      internal_run_file path
      return
    end

    object.auto_adopt or failure
  end

  def eval_template(slices)
    name = tokenize slices[:name]

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
