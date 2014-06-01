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

    def execute(event, *args)
      send event, *args
    rescue => e
      raise SlideField::RuntimeError,
        "#{@obj.context_string} An error occured while executing the '#{event}' event on the object '#{@obj.type}' at #{@obj.loc}:\n" +
        "\t(#{e.class}) #{e.message}"
    end

    def load; end
    def activate; end
    def draw(animator); end
    def deactivate; end
    def unload; end
  end
end
