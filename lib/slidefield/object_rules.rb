module SlideField::ObjectRules
  def self.[](type)
    type = type.to_s
    type[0] = type[0].upcase

    SlideField::ObjectRules.const_get(type).get
  rescue NameError
  end

  class Base
    @@cache = {}

    def initialize
      @properties = []
      @children = []
    end

    def properties_names
      @properties.collect {|hash| hash[:name] }
    end

    def properties_types
      @properties.collect {|hash| hash[:type] }.uniq
    end

    def required_properties
      required = @properties.select {|hash| hash[:default].nil? }
      required.collect {|hash| hash[:name] }
    end

    def optional_properties
      required = @properties.select {|hash| !hash[:default].nil? }
      required.collect {|hash| hash[:name] }
    end

    def type_of_property(name)
      rule = @properties.select {|hash| hash[:name] == name }.first
      rule[:type] if rule
    end

    def matching_properties(type)
      matches = @properties.select {|hash| hash[:type] == type }
      matches.collect {|hash| hash[:name] }
    end

    def default_value(name)
      rule = @properties.select {|hash| hash[:name] == name }.first
      rule[:default] if rule
    end

    def accepted_children
      @children.collect {|hash| hash[:type] }
    end

    def required_children
      required = @children.select {|hash| hash[:required] }
      required.collect {|hash| hash[:type] }
    end

    def self.get
      if instance = @@cache[self]
        instance
      else
        instance = self.new
        instance.rules
        @@cache[self] = instance
      end
    end

    protected
    def property(name, type, default = nil)
      @properties << {:name=>name, :type=>type, :default=>default}
    end

    def child(type, required = false)
      @children << {:type=>type, :required=>required}
    end
  end
end
