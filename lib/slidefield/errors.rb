module SlideField
  class Error < RuntimeError; end
  class ParseError < Error; end
  class InterpreterError < Error; end
  class RuntimeError < Error; end
end
