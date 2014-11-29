module SlideField::Doctor
  @@bag = {}
  @@output = nil

  def self.bag(klass = nil)
    if klass
      @@bag[klass] ||= []
      @@bag[klass]
    else
      @@bag
    end
  end

  def self.output; @@output end
  def self.output=(device) @@output = device end

private
  [:error, :note].each {|level|
    define_method('%s_at' % level) do |location, message|
      emit SF::Diagnostic.new(level, message, location)
    end
  }

  def emit(diagnostic)
    SF::Doctor.bag(self.class) << diagnostic

    diagnostic.send_to @@output if @@output

    diagnostic
  end
end
