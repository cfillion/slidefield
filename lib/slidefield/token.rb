class SlideField::Token
  def self.[](object, default_location = nil)
    if object.is_a? self
      object
    else
      new object, default_location
    end
  end

  attr_reader :value, :location

  def initialize(value, location = nil)
    @value = value.freeze
    @location = location || SF::Location.new
  end

  def ==(other)
    if other.is_a? self.class
      other.value == @value && other.location == @location
    else
      other == @value
    end
  end

  def to_i; @value.to_i end
  def to_s; @value.to_s end
  def to_sym; @value.to_sym end
end
