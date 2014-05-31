require File.expand_path('../helper', __FILE__)

module SlideField::ObjectRules
  class RulesTest < Base
    def rules
      property :var1, :string, "default"
      property :var2, :integer, nil
      property :var3, :string, "value"

      child :obj1
      child :obj2, true
      super
    end
  end
end

class TestObjectRules < MiniTest::Test
  def test_accessor
    klass = SlideField::ObjectRules::RulesTest
    assert_instance_of klass, SlideField::ObjectRules[:rulesTest]
  end

  def test_unknown
    assert_nil SlideField::ObjectRules[:thisDoesNotExist]
  end

  def test_cache
    klass = SlideField::ObjectRules::RulesTest
    first = klass.get
    second = klass.get

    assert_same first, second
  end

  def test_properties_names
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:var1, :var2, :var3], rules.properties_names
  end

  def test_properties_types
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:string, :integer], rules.properties_types
  end


  def test_required_properties
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:var2], rules.required_properties
  end

  def test_optional_properties
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:var1, :var3], rules.optional_properties
  end


  def test_type_of_property
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal :string, rules.type_of_property(:var1)
    assert_equal nil, rules.type_of_property(:unknown)
  end

  def test_matching_properties
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:var1, :var3], rules.matching_properties(:string)
  end

  def test_default_value
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal "default", rules.default_value(:var1)
    assert_equal nil, rules.default_value(:unknown)
  end

  def test_accepted_children
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:obj1, :obj2, :include, :debug], rules.accepted_children
  end

  def test_required_children
    rules = SlideField::ObjectRules::RulesTest.get
    assert_equal [:obj2], rules.required_children
  end
end
