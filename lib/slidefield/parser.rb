class SlideField::Parser < Parslet::Parser
  rule(:space) { match["\x20\t"] }
  rule(:spaces?) { space.repeat }
  rule(:inline_spaces?) { (space | any_comment).repeat }
  rule(:multiline_spaces?) { (match('\s') | any_comment).repeat }

  rule(:eof) { any.absent? }
  rule(:crlf) { match['\r\n'].repeat(1) }
  rule(:separator) { str(';') | crlf | eof }
  rule(:singleline_comment) { str('%') >> str('{').absent? >> (crlf.absent? >> any).repeat }
  rule(:multiline_comment) { str('%{') >> (str('%}').absent? >> any).repeat >> str('%}') }
  rule(:any_comment) { multiline_comment | singleline_comment }

  rule(:open) { multiline_spaces? >> str('{') >> multiline_spaces? }
  rule(:close) { multiline_spaces? >> str('}') }

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
  rule(:block) {
    open >>
    lines.as(:statements) >>
    close
  }

  rule(:filter) {
    str('(') >> spaces? >> (
      identifier.as(:name)
    ) >>
    spaces? >> str(')') >>
    inline_spaces?
  }

  rule(:value) {
    filter.repeat.as(:filters) >>
    (
      identifier.as(:identifier) |
      string.as(:string) |
      point.as(:point) |
      integer.as(:integer) |
      color.as(:color) |
      boolean.as(:boolean) |
      object.as(:object)
    )
  }

  rule(:assignment) {
    identifier.as(:variable) >>
    operator >>
    (
      value.as(:value) |
      block
    )
  }

  rule(:object) {
    str('\\') >>
    identifier.as(:type) >>
    inline_spaces? >>
    value.as(:value).maybe >>
    block.maybe
  }

  rule(:template) {
    str('\\&') >>
    identifier.as(:name)
  }

  rule(:statement) {
    (
      object.as(:object) |
      assignment.as(:assignment) |
      template.as(:template)
    ) >>
    inline_spaces? >>
    separator
  }

  rule(:line) {
    spaces? >>
    (
      statement |
      any_comment |
      crlf
    )
  }
  rule(:lines) { line.repeat }

  root :lines
end
