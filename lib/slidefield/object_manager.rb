module SlideField::ObjectManager
  def self.new(obj, window)
    type = obj.type.to_s
    type[0] = type[0].upcase
    const_get(type).new obj, window
  rescue NameError
  end

  class Base
    def initialize(obj, window)
      @obj = obj
      @window = window
    end

    def load; end
    def activate; end
    def draw; end
    def deactivate; end
    def unload; end
  end
end
