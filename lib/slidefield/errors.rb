module SlideField
  Error = Class.new StandardError

  AlreadyAdoptedError    = Class.new Error
  ColorOutOfBoundsError  = Class.new Error
  ForeignValueError      = Class.new Error
  UndefinedObjectError   = Class.new Error
end
