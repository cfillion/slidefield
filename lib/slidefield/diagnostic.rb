class SlideField::Diagnostic
  attr_reader :level, :message, :location

  def initialize(level, message, location)
    @level, @message, @location = level, message, location
    @enable_colors = STDOUT.tty?
  end 

  def to_s
    str = "%s: %s: %s" % [@location.to_s, @level, @message]

    if @enable_colors
      str.gsub! /<native code>:?/, '\0'.bold
      str.gsub! /[^\s:]+:\d+:\d+:?/, '\0'.bold

      str.gsub! /error:?/, '\0'.bold.red
      str.gsub! /warning:?/, '\0'.bold.yellow
      str.gsub! /debug:?/, '\0'.cyan
    end

    unless @location.native?
      code_excerpt, caret = excerpt
      caret = caret.bold.green if @enable_colors

      str += "\n  %s\n  %s" % [code_excerpt, caret]
    end

    str
  end

  alias :inspect :to_s

private
  def excerpt
    line_index = @location.line - 1
    column_index = @location.column - 1

    source_line = @location.context.source.lines[line_index]
    code_excerpt = source_line.strip
    column_index -= source_line.index code_excerpt
    caret = '%s^' % ["\x20" * column_index]

    [code_excerpt, caret]
  end
end
