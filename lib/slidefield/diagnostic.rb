class SlideField::Diagnostic
  attr_reader :level, :message, :location

  def initialize(level, message, location)
    @level, @message, @location = level, message, location
  end 

  def format(colors: true, excerpt: true)
    excerpt = false if @location.context.source.nil?

    output = "%s: %s: %s" % [@location.to_s, @level, @message]

    if excerpt
      excerpt_parts = make_excerpt
      excerpt_parts.map! {|s| '  ' + s } # add padding

      output += "\n%s\n%s" % excerpt_parts
    end

    highlight output if colors

    output
  end

  def send_to(device)
    device.puts format colors: device.tty?
  end

  def to_s
    format colors: false, excerpt: false
  end

  alias :inspect :to_s

private
  def make_excerpt
    line_index = @location.line - 1
    column_index = @location.column - 1

    source_line = @location.context.source.lines[line_index]
    code_excerpt = source_line.strip
    column_index -= source_line.index code_excerpt
    caret = '%s^' % ["\x20" * column_index]

    [code_excerpt, caret]
  end

  def highlight(str)
    str.gsub! /<native code>:?/, '\0'.bold
    str.gsub! /[^\s:]+:\d+:\d+:?/, '\0'.bold

    str.gsub! /error:?/, '\0'.bold.red
    str.gsub! /warning:?/, '\0'.bold.yellow
    str.gsub! /debug:?/, '\0'.cyan

    str.gsub! /^\s+\^\z/, '\0'.bold.green
  end
end
