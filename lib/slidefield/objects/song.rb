module SlideField::ObjectRules
  class Song < SBase
    def rules
      property :source, :string
      property :volume, :integer, 100
      property :loop, :boolean, true

      super
    end
  end
end

module SlideField::ObjectManager
  class Song < Base
    def on_load
      source = File.expand_path @obj.get(:source), @obj.include_path
      @loop = @obj.get(:loop)
      @volume = @obj.get(:volume) / 100.0

      @song = Gosu::Sample.new @window, source
    end

    def on_activate
      @instance = @song.play @volume, 1, @loop
    end

    def on_deactivate
      @instance.stop
      @instance = nil
    end

    def on_unload
      @song = nil
    end
  end
end
