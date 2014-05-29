class SlideField::Parser < Parslet::Parser
  rule(:space) { match["\x20\t"] }
  rule(:spaces?) { space.repeat }
  rule(:inline_spaces?) { (space | any_comment).repeat }
  rule(:multi_spaces?) { (match('\s') | any_comment).repeat }

  rule(:eof) { any.absent? }
  rule(:crlf) { match['\r\n'].repeat(1) }
  rule(:separator) { str(';') | crlf | eof }
  rule(:line_comment) { str('%') >> (str('{').absent? >> crlf.absent? >> any).repeat }
  rule(:multi_comment) { str('%{') >> (str('%}').absent? >> any).repeat >> str('%}') }
  rule(:any_comment) { multi_comment | line_comment }

  rule(:open) { multi_spaces? >> str('{') >> multi_spaces? }
  rule(:close) { multi_spaces? >> str('}') }

  rule(:assign) { str('=') }
  rule(:add) { str('+=') }
  rule(:subtract) { str('-=') }
  rule(:multiply) { str('*=') }
  rule(:divide) { str('/=') }
  rule(:operator) {
    inline_spaces? >> (
      assign |
      add |
      subtract |
      multiply |
      divide
    ).as(:operator) >>
    inline_spaces?
  }

  rule(:identifier) { match['a-zA-Z_'] >> match['a-zA-Z0-9_'].repeat }
  rule(:integer) { str('-').maybe >> match('\\d').repeat(1) }
  rule(:point) { integer >> str('x') >> integer }
  rule(:color) { str('#') >> match['a-fA-F0-9'].repeat(8, 8) }
  rule(:boolean) { str(':') >> (str('true') | str('false')) }
  rule(:string) {
    str('"') >> (
      (str('\\') >> any) |
      (str('"').absent? >> any)
    ).repeat >>
    str('"')
  }

  rule(:obj_type) { str('\\') >> identifier.as(:type) >> inline_spaces? }
  rule(:cast) { str('(') >> identifier.as(:cast) >> str(')') >> inline_spaces? }
  rule(:value) {
    cast.maybe >>
    (
      identifier.as(:identifier) |
      string.as(:string) |
      point.as(:point) |
      integer.as(:integer) |
      color.as(:color) |
      boolean.as(:boolean)
    )
  }

  rule(:assignment) { identifier.as(:variable) >> operator >> value.as(:value) }
  rule(:object) {
    obj_type >>
    value.as(:value).maybe >>
    (
      open >>
      statements.as(:body) >>
      close
    ).maybe
  }

  rule(:expression) {
    (
      object.as(:object) |
      assignment.as(:assignment)
    ) >>
    inline_spaces? >>
    separator
  }
  rule(:statement) {
    spaces? >>
    (
      expression |
      any_comment |
      crlf
    )
  }
  rule(:statements) { statement.repeat }

  root(:statements)
end
