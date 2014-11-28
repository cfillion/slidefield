class String
  def filter_lines
    self.lines.count
  end
end

class Fixnum
  def filter_x
    SF::Point.new self, 0
  end

  def filter_y
    SF::Point.new 0, self
  end

  def filter_r
    SF::Color.new self, 0, 0, 0
  end

  def filter_g
    SF::Color.new 0, self, 0, 0
  end

  def filter_b
    SF::Color.new 0, 0, self, 0
  end

  def filter_a
    SF::Color.new 0, 0, 0, self
  end
end

class SlideField::Boolean
  def self.true
    new true
  end

  def self.false
    new false
  end

  def initialize(value)
    @value = value
  end

  def to_bool
    @value
  end

  def ==(other)
    other.respond_to?(:to_bool) && @value == other.to_bool
  end

  def to_s
    @value.to_s
  end

  alias :inspect :to_s
end

module SlideField::ArrayType
  def ==(other)
    other.respond_to?(:to_a) && self.to_a == other.to_a
  end

  [:+, :-, :*, :/].each { |operator|
    define_method operator do |other|
      raise TypeError unless other.class == self.class

      self.class.new *[self.to_a, other.to_a].
        transpose.map {|x| x.reduce operator }
    end
  }
end

class SlideField::Point
  include SF::ArrayType

  attr_reader :x, :y

  def self.zero
    new 0, 0
  end

  def initialize(x, y)
    @x, @y = x, y
  end

  alias :filter_x :x
  alias :filter_y :y

  def to_a
    [@x, @y]
  end


  def to_s
    '%dx%d' % to_a
  end

  alias :inspect :to_s
end

class SlideField::Color
  include SF::ArrayType

  attr_reader :r, :g, :b, :a

  VALID_RANGE = (0..255).freeze

  def self.white
    new 255, 255, 255, 255
  end

  def self.black
    new 0, 0, 0, 255
  end

  def initialize(r, g, b, a)
    @r, @g, @b, @a = r, g, b, a

    unless to_a.all? {|c| VALID_RANGE.include? c }
      raise SF::ColorOutOfBoundsError
    end
  end

  alias :filter_r :r
  alias :filter_g :g
  alias :filter_b :b
  alias :filter_a :a

  def to_a
    [@r, @g, @b, @a]
  end

  def to_s
    "#%X%X%X%X" % to_a
  end

  alias :inspect :to_s
end

SF::Template = Struct.new :context, :statements do
  def to_s
    '<Template>'
  end

  alias :inspect :to_s
end
