require File.expand_path '../helper', __FILE__

SF::Object.define :first do end
SF::Object.define :second do
  set_variable :predefined, 'predefined'
end
SF::Object.define :third do end
SF::Object.define :nodefault do
  set_variable :unset, String
end

class TestObject < MiniTest::Test
  include DoctorHelper

  def diagnostics
    SF::Doctor.bag SF::Object
  end

  def link_to(object)
    context = SF::Context.new
    context.object = object

    SF::Location.new context
  end

  def test_infinity
    assert_equal Float::INFINITY, SF::Object::Infinity
  end

  def test_create
    loc = SF::Location.new
    first = SF::Object.new :first, loc

    assert_equal :first, first.type
    assert_same loc, first.location
  end

  def test_create_unknown
    loc = SF::Location.new

    error = assert_raises SF::UndefinedObjectError do
      SF::Object.new :qwfpgjluy, loc
    end

    dia = assert_diagnostic :error, "unknown object name 'qwfpgjluy'"
    assert_same loc, dia.location

    assert_equal dia.to_s, error.message
  end

  def test_set_variable
    first = SF::Object.new :first
    var = SF::Variable.new 42

    refute first.has_variable? :qwfpgjluy
    first.set_variable :qwfpgjluy, var
    assert first.has_variable? :qwfpgjluy

    assert_same var, first.get_variable(:qwfpgjluy)
  end

  def test_set_value
    first = SF::Object.new :first
    loc = SF::Location.new

    first.set_variable :qwfpgjluy, 42, loc
    first.set_variable :arstdhnei, 24

    qwfpgjluy = first.get_variable :qwfpgjluy
    assert_equal 42, qwfpgjluy.value
    assert_same loc, qwfpgjluy.location

    arstdhnei = first.get_variable :arstdhnei
    assert_equal 24, arstdhnei.value
  end

  def test_variable_with_token
    first = SF::Object.new :first
    first.set_variable SF::Token.new(:qwfpgjluy), 42

    assert_equal 42, first.get_variable(:qwfpgjluy)
    assert_equal 42, first.get_variable(SF::Token.new(:qwfpgjluy))
  end

  def test_reset_variable
    first = SF::Object.new :first

    first.set_variable :qwfpgjluy, 1
    first.set_variable :qwfpgjluy, 42
  end

  def test_reset_variable_incompatible
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, 42

    var = SF::Variable.new 'hello'
    retval = first.set_variable :qwfpgjluy, var
    assert_equal false, retval

    dia = assert_diagnostic :error,
      "incompatible assignation ('integer' to 'string')"
    assert_same var.location, dia.location
  end

  def test_get_variable_undefined
    first = SF::Object.new :first

    token = SF::Token.new :qwfpgjluy
    assert_equal false, first.get_variable(token)

    dia = assert_diagnostic :error, "undefined variable 'qwfpgjluy'"
    assert_same token.location, dia.location
  end

  def test_get_variable_uninitialized
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum

    token = SF::Token.new :qwfpgjluy
    assert_equal false, first.get_variable(token)

    dia = assert_diagnostic :error,
      "use of uninitialized variable 'qwfpgjluy'"
    assert_same token.location, dia.location
  end

  def test_value_of
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, 42

    assert_equal 42, first.value_of(:qwfpgjluy)
    assert_equal 42, first.value_of(SF::Token.new(:qwfpgjluy))
  end

  def test_value_of_uninitialized
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum

    assert_equal false, first.value_of(:qwfpgjluy)

    assert_diagnostic :error, "use of uninitialized variable 'qwfpgjluy'"
  end

  def test_guess_variable
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum
    first.set_variable :arstdhnei, String

    assert_equal :arstdhnei, first.guess_variable('hello world')
    assert_equal :arstdhnei,
      first.guess_variable(SF::Variable.new('hello world'))
  end

  def test_guess_variable_fail
    first = SF::Object.new :first

    var = SF::Variable.new 42
    assert_equal false, first.guess_variable(var)
    assert_equal false, first.guess_variable(42)

    dia = assert_diagnostic :error,
      "object 'first' has no uninitialized variable compatible with 'integer'"
    assert_same var.location, dia.location

    assert_equal dia.message, diagnostics.shift.message
  end

  def test_guess_initialized_variable
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, 42

    assert_equal false, first.guess_variable(42)

    assert_diagnostic :error,
      "object 'first' has no uninitialized variable compatible with 'integer'"
  end

  def test_guess_variable_ambiguous
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum
    first.set_variable :arstdhnei, Fixnum

    var = SF::Variable.new 42
    assert_equal false, first.guess_variable(var)
    assert_equal false, first.guess_variable(42)

    dia = assert_diagnostic :error, 'value is ambiguous'
    assert_same var.location, dia.location

    assert_equal dia.message, diagnostics.shift.message
  end

  def test_guess_variable_ignore_non_native
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum, SF::Location.new(SF::Context.new)
    first.set_variable :arstdhnei, Fixnum

    assert_equal :arstdhnei, first.guess_variable(42)
  end

  def test_adopt
    first = SF::Object.new :first
    first.allow_children :second

    second = SF::Object.new :second
    assert first.knows? second
    assert_empty first.children

    assert_equal true, first.adopt(second)

    bag = first.children
    assert_same second, bag.shift
    assert_empty bag

    refute_empty first.children
  end

  def test_adopt_overflow
    first = SF::Object.new :first
    first.allow_children :second, max: 2

    first.adopt SF::Object.new(:second)
    first.adopt SF::Object.new(:second)

    extra = SF::Object.new(:second)
    assert_equal false, first.adopt(extra)

    dia = assert_diagnostic :error,
      "object 'first' cannot have more than 2 'second'"
    assert_same extra.location, dia.location
  end

  def test_adopt_unwanted
    first = SF::Object.new :first
    second = SF::Object.new :second

    refute first.knows? second

    assert_equal false, first.adopt(second)

    dia = assert_diagnostic :error, "object 'first' cannot have 'second'"
    assert_same second.location, dia.location
  end

  def test_readopt
    first_parent = SF::Object.new :first
    first_parent.allow_children :second

    second_parent = SF::Object.new :first
    second_parent.allow_children :second

    second = SF::Object.new :second
    first_parent.adopt second

    assert_raises SF::AlreadyAdoptedError do
      second_parent.adopt second
    end
  end

  def test_finalize
    first = SF::Object.new :first
    first.allow_children :second

    second = SF::Object.new :second, link_to(first)

    assert_equal true, second.finalize
    assert_equal [second], first.children
  end

  def test_finalize_unwanted
    first = SF::Object.new :first

    assert_equal false, first.finalize

    dia = assert_diagnostic :error,
      "object 'first' is not allowed in this context"
    assert_same first.location, dia.location
  end

  def test_finalize_passthrough_disabled
    first = SF::Object.new :first
    first.allow_children :second
    first.allow_children :third

    second = SF::Object.new :second, link_to(first)
    third = SF::Object.new :third, link_to(second)

    second.set_passthrough false

    assert_equal false, third.finalize
    assert_equal [second], first.children

    assert_diagnostic :error, "object 'third' is not allowed in this context"
  end

  def test_finalize_passthrough_enabled
    first = SF::Object.new :first
    first.allow_children :second
    first.allow_children :third

    second = SF::Object.new :second, link_to(first)
    third = SF::Object.new :third, link_to(second)

    second.set_passthrough true

    assert_equal true, third.finalize
    assert_equal [second, third], first.children
    assert_empty second.children
  end

  def test_finalize_passthrough_parent_unwanted
    first = SF::Object.new :first
    first.allow_children :third

    second = SF::Object.new :second, link_to(first)
    third = SF::Object.new :third, link_to(second)

    second.set_passthrough true

    assert_equal false, third.finalize
    assert_empty first.children
    assert_empty second.children

    assert_diagnostic :error, "object 'second' is not allowed in this context"
  end

  def test_block_finalize
    first = SF::Object.new :first
    first.allow_children :second

    second = SF::Object.new :second, link_to(first)
    second.allow_children :third

    second.block_finalize!
    assert_equal true, second.finalize

    assert_equal [], first.children
  end

  def test_inherit
    first = SF::Object.new :first
    first.set_variable :var, 42

    second = SF::Object.new :second, link_to(first)

    assert second.has_variable? :var
    assert_equal first.get_variable(:var), second.get_variable(:var)
  end

  def test_inherit_incompatible
    first = SF::Object.new :first
    first.set_variable :predefined, 42

    second = SF::Object.new :second, link_to(first)

    assert_equal 'predefined', second.value_of(:predefined)
  end

  def test_inherit_early_uninitialized
    nodefault = SF::Object.new :nodefault

    obj = SF::Object.new :level1, link_to(nodefault)
    assert_equal false, obj.has_variable?(:unset)
  end

  def test_select_children
    first = SF::Object.new :first
    first.allow_children :second
    first.allow_children :third

    second = SF::Object.new :second
    first.adopt second

    brother1 = SF::Object.new :third
    brother2 = SF::Object.new :third
    first.adopt brother1
    first.adopt brother2

    assert_equal [second], first.children(:second)
    assert_equal [brother1, brother2], first.children(:third)
  end

  def test_first_child
    first = SF::Object.new :first
    first.allow_children :second

    first_second = SF::Object.new :second
    second_second = SF::Object.new :second

    first.adopt first_second
    first.adopt second_second

    assert_same first_second, first.first_child(:second)
    assert_nil first.first_child(:qwfpgjluy)
  end

  def test_count
    first = SF::Object.new :first
    first.allow_children :second
    first.allow_children :third

    assert_equal 0, first.count

    first.adopt SF::Object.new(:second)
    assert_equal 1, first.count
    assert_equal 1, first.count(:second)

    first.adopt SF::Object.new(:third)
    assert_equal 2, first.count
    assert_equal 1, first.count(:third)
  end

  def test_copy
    loc = SF::Location.new

    original = SF::Object.new :first
    original.set_variable :hello, 'world'
    original.set_passthrough true
    original.allow_children :second
    original.adopt SF::Object.new(:second)

    copy = original.copy loc

    refute_same copy, original

    refute_same copy.location, original.location
    assert_same loc, copy.location

    assert_equal false, copy.passthrough?

    assert_equal 'world', copy.value_of(:hello)
    assert_equal copy.children, original.children
  end

  def test_is_root
    root = SF::Object.new :first
    assert_equal true, root.root?

    branch = SF::Object.new :second, link_to(root)
    assert_equal false, branch.root?
  end

  def test_validate
    first = SF::Object.new :first
    first.allow_children :second, min: 1

    var_loc = SF::Location.new
    first.set_variable :qwfpgjluy, String, var_loc

    assert_equal false, first.validate

    # uninitialized variables
    dia = assert_diagnostic :warning, "'qwfpgjluy' is uninitialized"
    assert_same var_loc, dia.location

    dia = assert_diagnostic :error,
      "object 'first' has one or more uninitialized variables"
    assert_same first.location, dia.location

    # unmet requirements
    dia = assert_diagnostic :error,
      "object 'first' must have at least 1 'second', found 0"
    assert_same first.location, dia.location
  end

  def test_validate_on_adopt
    first = SF::Object.new :first
    first.allow_children :second

    second = SF::Object.new :second
    second.allow_children :third, min: 3

    assert_equal false, first.adopt(second)

    assert_diagnostic :error,
      "object 'second' must have at least 3 'third', found 0"
  end

  def test_inspect
    first = SF::Object.new :first

    assert_equal '\\first@<native code>', first.inspect
  end

  def test_passthrough
    first = SF::Object.new :first
    assert_equal false, first.passthrough?

    first.set_passthrough
    assert_equal true, first.passthrough?

    first.set_passthrough false
    assert_equal false, first.passthrough?

    first.set_passthrough :trueish
    assert_equal true, first.passthrough?
  end
end
