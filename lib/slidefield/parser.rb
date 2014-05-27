class SlideField::Parser < Parslet::Parser
  rule(:spaces?) { match["\x20\t"].repeat }
  rule(:white?) { match('\s').repeat >> comment.maybe }

  rule(:eof) { any.absent? }
  rule(:crlf) { match['\r\n'].repeat(1) }
  rule(:separator) { spaces? >> (str(';') | crlf | comment) }
  rule(:line_comment) { str('%') >> (crlf.absent? >> any).repeat >> (crlf | eof) }
  rule(:multi_comment) { str('%{') >> (str('%}').absent? >> any).repeat >> str('%}') >> crlf.maybe }
  rule(:comment) { multi_comment | line_comment }

  rule(:open) { white? >> match('{') >> white? }
  rule(:close) { white? >> match('}') >> white? }

  rule(:assign) { str('=') }
  rule(:addition) { str('+=') }
  rule(:subtraction) { str('-=') }
  rule(:operator) { spaces? >> (assign | addition | subtraction).as(:operator) >> spaces? }

  rule(:identifier) { match['a-zA-Z_'] >> match['a-zA-Z0-9_'].repeat }
  rule(:number) { str('-').maybe >> match('\\d').repeat(1) }
  rule(:size) { number >> str('x') >> number }
  rule(:color) { str('#') >> match['a-fA-F0-9'].repeat(8, 8) }
  rule(:string) {
    str('"') >> (
      (str('\\') >> any) |
      (str('"').absent? >> any)
    ).repeat >>
    str('"')
  }

  rule(:obj_type) { spaces? >> str('\\') >> identifier.as(:type) }
  rule(:value) {
    spaces? >> (
      identifier.as(:identifier) |
      string.as(:string) |
      size.as(:size) |
      number.as(:number) |
      color.as(:color)
    ) >> spaces?
  }

  rule(:assignment) { spaces? >> identifier.as(:variable) >> operator >> value.as(:value) >> (separator | eof) }
  rule(:object) { obj_type >> value.as(:value).maybe >> (open >> statement.repeat.as(:body) >> close | separator | eof) }

  rule(:statement) { object.as(:object) | assignment.as(:assignment) | comment | separator }
  rule(:statements) { statement.repeat }

  root(:statements)
end
