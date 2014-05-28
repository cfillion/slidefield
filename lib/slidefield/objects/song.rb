module SlideField::ObjectRules
  class Song < SBase
    def rules
      variable :source, :string
      variable :volume, :integer, 100
      variable :loop, :boolean, true

      super
    end
  end
end

module SlideField::ObjectManager
  class Song < Base
    def load
      source = File.expand_path @obj.get(:source), @obj.include_path
      @loop = @obj.get(:loop)
      @volume = @obj.get(:volume) / 100.0

      @song = Gosu::Sample.new @window, source
    end

    def activate
      @instance = @song.play @volume, 1, @loop
    end

    def deactivate
      @instance.stop
    end
  end
end
