module SlideField
  Error = Class.new StandardError

  AlreadyAdoptedError    = Class.new Error
  AmbiguousValueError    = Class.new Error
  ColorOutOfBoundsError  = Class.new Error
  ForeignValueError      = Class.new Error
  IncompatibleValueError = Class.new Error
  InvalidObjectError     = Class.new Error
  UnauthorizedChildError = Class.new Error
  UndefinedObjectError   = Class.new Error
  VariableNotFoundError  = Class.new Error
end
