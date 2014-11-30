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

    dia = diagnostics.shift
    assert_equal :error, dia.level
    assert_equal "unknown object name 'qwfpgjluy'", dia.message
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

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "incompatible assignation ('integer' to 'string')", error.message
    assert_same var.location, error.location
  end

  def test_get_variable_undefined
    first = SF::Object.new :first

    token = SF::Token.new :qwfpgjluy
    assert_equal false, first.get_variable(token)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "undefined variable 'qwfpgjluy'", error.message
    assert_same token.location, error.location
  end

  def test_get_variable_uninitialized
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum

    token = SF::Token.new :qwfpgjluy
    assert_equal false, first.get_variable(token)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "use of uninitialized variable 'qwfpgjluy'", error.message
    assert_same token.location, error.location
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

    diagnostics.shift
  end

  def test_guess_variable
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum
    first.set_variable :arstdhnei, String

    assert_equal :arstdhnei, first.guess_variable("hello world")
    assert_equal :arstdhnei, first.guess_variable(SF::Variable.new("hello world"))
  end

  def test_guess_variable_fail
    first = SF::Object.new :first

    var = SF::Variable.new 42
    assert_equal false, first.guess_variable(var)
    assert_equal false, first.guess_variable(42)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "object 'first' has no uninitialized variable compatible with 'integer'", error.message
    assert_same var.location, error.location

    assert_equal error.message, diagnostics.shift.message
  end

  def test_guess_initialized_variable
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, 42

    assert_equal false, first.guess_variable(42)

    error = diagnostics.shift
    assert_equal "object 'first' has no uninitialized variable compatible with 'integer'", error.message
  end

  def test_guess_variable_ambiguous
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum
    first.set_variable :arstdhnei, Fixnum

    var = SF::Variable.new 42
    assert_equal false, first.guess_variable(var)
    assert_equal false, first.guess_variable(42)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'value is ambiguous', error.message
    assert_same var.location, error.location

    assert_equal error.message, diagnostics.shift.message
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

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "object 'first' cannot have more than 2 'second'", error.message
    assert_same extra.location, error.location
  end

  def test_adopt_unwanted
    first = SF::Object.new :first
    second = SF::Object.new :second

    refute first.knows? second

    assert_equal false, first.adopt(second)

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "object 'first' cannot have 'second'", error.message
    assert_same second.location, error.location
  end

  def test_readopt
    first_parent = SF::Object.new :first
    first_parent.allow_children :second

    second_parent = first_parent.clone

    second = SF::Object.new :second
    first_parent.adopt second

    assert_raises SF::AlreadyAdoptedError do
      second_parent.adopt second
    end
  end

  def test_auto_adopt
    first = SF::Object.new :first
    first.allow_children :second

    second_context = SF::Context.new
    second_context.object = first
    second = SF::Object.new :second, SF::Location.new(second_context)

    assert_equal true, second.auto_adopt
    assert_equal [second], first.children
  end

  def test_auto_adopt_through_opaque
    first = SF::Object.new :first
    first.allow_children :second
    first.allow_children :third

    second_context = SF::Context.new
    second_context.object = first
    second = SF::Object.new :second, SF::Location.new(second_context)

    third_context = SF::Context.new
    third_context.object = second
    third = SF::Object.new :third, SF::Location.new(third_context)

    assert_equal false, third.auto_adopt
    diagnostics.shift

    assert_equal [second], first.children
  end

  def test_auto_adopt_through_transparent
    first = SF::Object.new :first
    first.allow_children :second
    first.allow_children :third

    second_context = SF::Context.new
    second_context.object = first
    second = SF::Object.new :second, SF::Location.new(second_context)

    third_context = SF::Context.new
    third_context.object = second
    third = SF::Object.new :third, SF::Location.new(third_context)

    second.transparentize!
    refute second.opaque?

    assert_equal true, third.auto_adopt
    assert_equal [second, third], first.children
  end

  def test_auto_adopt_unwanted
    first = SF::Object.new :first

    assert_equal false, first.auto_adopt
    error = diagnostics.shift

    assert_equal :error, error.level
    assert_equal "object 'first' is not allowed in this context", error.message
    assert_same first.location, error.location
  end

  def test_block_auto_adopt
    first = SF::Object.new :first
    first.allow_children :second

    second_context = SF::Context.new
    second_context.object = first
    second = SF::Object.new :second, SF::Location.new(second_context)
    second.allow_children :third

    second.block_auto_adopt!
    assert_equal true, second.auto_adopt

    assert_equal [], first.children
  end

  def test_inherit
    first = SF::Object.new :first
    first.set_variable :var, 42

    context = SF::Context.new
    context.object = first

    second = SF::Object.new :second, SF::Location.new(context)

    assert second.has_variable? :var
    assert_equal first.get_variable(:var), second.get_variable(:var)
  end

  def test_inherit_incompatible
    first = SF::Object.new :first
    first.set_variable :predefined, 42

    context = SF::Context.new
    context.object = first

    second = SF::Object.new :second, SF::Location.new(context)

    assert_equal 'predefined', second.value_of(:predefined)
  end

  def test_inherit_early_uninitialized
    nodefault = SF::Object.new :nodefault

    context = SF::Context.new
    context.object = nodefault

    SF::Object.new :nodefault, SF::Location.new(context)
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
    original.transparentize!
    original.allow_children :second
    original.adopt SF::Object.new(:second)

    copy = original.copy loc

    refute_same copy, original

    refute_same copy.location, original.location
    assert_same loc, copy.location

    assert_equal true, copy.opaque?

    assert_equal 'world', copy.value_of(:hello)
    assert_equal copy.children, original.children
  end

  def test_is_root
    root = SF::Object.new :first
    assert_equal true, root.root?

    context = SF::Context.new
    context.object = root

    branch = SF::Object.new :second, SF::Location.new(context)
    assert_equal false, branch.root?
  end

  def test_validate_children
    first = SF::Object.new :first

    first.allow_children :second, min: 2
    first.adopt SF::Object.new(:second)

    first.allow_children :third, min: 1

    assert_equal false, first.valid?

    dia = diagnostics.shift
    assert_equal :error, dia.level
    assert_equal "object 'first' must have at least 2 'second', got 1", dia.message
    assert_same first.location, dia.location

    dia = diagnostics.shift
    assert_equal "object 'first' must have at least 1 'third', got 0", dia.message
  end

  def test_validate_uninitialized
    var_loc = SF::Location.new

    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, String, var_loc

    assert_equal false, first.valid?

    dia = diagnostics.shift
    assert_equal :warning, dia.level
    assert_equal "'qwfpgjluy' is uninitialized", dia.message
    assert_same var_loc, dia.location

    dia = diagnostics.shift
    assert_equal :error, dia.level
    assert_equal "object 'first' has one or more uninitialized variables", dia.message
    assert_same first.location, dia.location
  end

  def test_inspect
    first = SF::Object.new :first

    assert_equal '\\first@<native code>', first.inspect
  end
end
