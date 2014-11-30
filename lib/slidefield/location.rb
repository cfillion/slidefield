class SlideField::Location
  SF::Context = Struct.new :label, :include_path, :object, :source

  attr_reader :context, :line, :column

  def initialize(context = nil, line = 0, column = 0)
    @is_native = context.nil?

    context ||= SF::Context.new
    @context, @line, @column = context, line, column
  end

  def native?
    @is_native
  end

  def line_and_column
    [@line, @column]
  end

  def ==(other)
    other.context == @context && other.line == @line && other.column == @column
  end

  def to_s
    if native?
      '<native code>'
    else
      '%s:%d:%d' % [@context.label, @line, @column]
    end
  end

  alias :inspect :to_s
end
