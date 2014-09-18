module SlideField
  Error            = Class.new RuntimeError

  ParseError       = Class.new Error
  InterpreterError = Class.new Error
  RuntimeError     = Class.new Error
end
