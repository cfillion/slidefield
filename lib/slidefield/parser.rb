class SlideField::Parser < Parslet::Parser
  rule(:spaces?) { match["\x20\t"].repeat }
  rule(:white?) { match('\s').repeat >> comment.maybe >> match('\s').repeat }

  rule(:eof) { any.absent? }
  rule(:crlf) { match['\r\n'].repeat(1) }
  rule(:separator) { spaces? >> (str(';') | crlf | comment) }
  rule(:line_comment) { str('%') >> (crlf.absent? >> any).repeat >> (crlf | eof) }
  rule(:multi_comment) { str('%{') >> (str('%}').absent? >> any).repeat >> str('%}') >> crlf.maybe }
  rule(:comment) { multi_comment | line_comment }

  rule(:open) { white? >> match('{') >> white? }
  rule(:close) { white? >> match('}') >> white? }

  rule(:assign) { str('=') }
  rule(:add) { str('+=') }
  rule(:subtract) { str('-=') }
  rule(:multiply) { str('*=') }
  rule(:divide) { str('/=') }
  rule(:operator) { spaces? >> (assign | add | subtract | multiply | divide).as(:operator) >> spaces? }

  rule(:identifier) { match['a-zA-Z_'] >> match['a-zA-Z0-9_'].repeat }
  rule(:integer) { str('-').maybe >> match('\\d').repeat(1) }
  rule(:size) { integer >> str('x') >> integer }
  rule(:color) { str('#') >> match['a-fA-F0-9'].repeat(8, 8) }
  rule(:boolean) { str(':') >> (str('true') | str('false')) }
  rule(:string) {
    str('"') >> (
      (str('\\') >> any) |
      (str('"').absent? >> any)
    ).repeat >>
    str('"')
  }

  rule(:obj_type) { str('\\') >> identifier.as(:type) >> spaces? }
  rule(:cast) { str('(') >> identifier.as(:cast) >> str(')') >> spaces? }
  rule(:value) {
    cast.maybe >>
    (
      identifier.as(:identifier) |
      string.as(:string) |
      size.as(:size) |
      integer.as(:integer) |
      color.as(:color) |
      boolean.as(:boolean)
    ) >> spaces?
  }

  rule(:assignment) { identifier.as(:variable) >> operator >> value.as(:value) >> (separator | eof) }
  rule(:object) { obj_type >> value.as(:value).maybe >> (open >> statement.repeat.as(:body) >> close | separator | eof) }

  rule(:statement) { spaces? >> (object.as(:object) | assignment.as(:assignment) | comment | separator) }
  rule(:statements) { statement.repeat }

  root(:statements)
end
