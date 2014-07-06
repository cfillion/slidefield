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
      SlideField.debug "Event: #{event} (#{@obj.type} in #{@obj.context} at #{@obj.loc})"
      send "on_#{event}", *args
    rescue => e
      SlideField.debug "Backtrace: #{e.backtrace.join "\n"}"
      raise SlideField::RuntimeError,
        "#{@obj.context_string} An error occured while executing the '#{event}' event on the object '#{@obj.type}' at #{@obj.loc}:\n" +
        "\t(#{e.class}) #{e.message}"
    end

    def method_missing(method, *args)
      raise NameError, "No such event" if method.to_s.start_with? 'on_'
      execute method, *args
    end

    def on_load; end
    def on_activate; end
    def on_draw(animator); end
    def on_deactivate; end
    def on_unload; end
  end
end
