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
      @variables = []
      @children = []
    end

    def known_variables
      @variables.map {|hash| hash[:name] }
    end

    def known_variables_types
      @variables.map {|hash| hash[:type] }.uniq
    end

    def required_variables
      required = @variables.select {|hash| hash[:default].nil? }
      required.map {|hash| hash[:name] }
    end

    def optional_variables
      required = @variables.select {|hash| !hash[:default].nil? }
      required.map {|hash| hash[:name] }
    end

    def type_of(name)
      rule = @variables.select {|hash| hash[:name] == name }.first
      rule[:type] if rule
    end

    def matching_variables(type)
      matches = @variables.select {|hash| hash[:type] == type }
      matches.map {|hash| hash[:name] }
    end

    def default_value(name)
      rule = @variables.select {|hash| hash[:name] == name }.first
      rule[:default] if rule
    end

    def accepted_children
      @children.map {|hash| hash[:type] }
    end

    def required_children
      required = @children.select {|hash| hash[:required] }
      required.map {|hash| hash[:type] }
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
    def variable(name, type, default = nil)
      @variables << {:name=>name, :type=>type, :default=>default}
    end

    def child(type, required = false)
      @children << {:type=>type, :required=>required}
    end
  end
end
