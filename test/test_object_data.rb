require File.expand_path('../helper', __FILE__)

class TestObjectData < MiniTest::Test
  def test_initialize
    o = SlideField::ObjectData.new :test, 'location'
    assert_equal :test, o.type
    assert_equal 'location', o.loc
  end

  def test_variables
    o = SlideField::ObjectData.new :test, 'loc'
    refute o.has? :test
    assert_nil o.get(:test)
    assert_nil o.var_type(:test)
    assert_nil o.var_loc(:test)

    o.set :test, 'hello world', 'line 42 char 24', :string
    assert o.has? :test
    assert_equal 'hello world', o.get(:test)
    assert_equal :string, o.var_type(:test)
    assert_equal 'line 42 char 24', o.var_loc(:test)

    o.set :test, 'hello tester'
    assert_equal 'hello tester', o.get(:test)
    assert_equal :string, o.var_type(:test)
    assert_equal 'line 42 char 24', o.var_loc(:test)
  end

  def test_children
    parent = SlideField::ObjectData.new :parent, 'loc'
    assert_equal [], parent.children

    child1 = SlideField::ObjectData.new :child, 'loc'
    child2 = SlideField::ObjectData.new :child, 'loc'
    child3 = SlideField::ObjectData.new :uniqueOfHisKind, 'loc'

    parent << child1
    parent << child2
    parent << child3

    assert_equal [child1, child2, child3], parent.children
    assert_equal [child1, child2], parent[:child]
    assert_equal [child3], parent[:uniqueOfHisKind]

    assert_equal parent, child1.parent
    assert_equal parent, child2.parent
    assert_equal parent, child3.parent
  end

  def test_inheritance
    parent = SlideField::ObjectData.new :parent, 'loc'
    parent.set 'variable', 'value', 'loc', :type

    child = SlideField::ObjectData.new :child, 'loc'
    parent << child

    assert parent.has?('variable')
    refute child.has?('variable')
    assert_equal 'value', child.get('variable')
    assert_equal :type, child.var_type('variable')
    assert_equal 'loc', child.var_loc('variable')
  end

  def test_context_string
    o1 = SlideField::ObjectData.new :test, 'loc'
    o1.context = 'context1'

    o2 = SlideField::ObjectData.new :test, 'loc'
    o2.context = 'context2'
    o1 << o2

    o3 = SlideField::ObjectData.new :test, 'loc'
    o3.context = 'context2'
    o2 << o3

    o4 = SlideField::ObjectData.new :test, 'loc'
    o4.context = 'context1'
    o3 << o4

    assert_equal "[context1]", o1.context_string
    assert_equal "[context1] [context2]", o2.context_string
    assert_equal "[context1] [context2]", o3.context_string
    assert_equal "[context1] [context2] [context1]", o4.context_string
  end
end
