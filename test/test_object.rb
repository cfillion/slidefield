require File.expand_path '../helper', __FILE__

SF::Object.define :first do end
SF::Object.define :second do
  set_variable :predefined, 'predefined'
end
SF::Object.define :third do end

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
    loc = SF::Location.new

    refute first.has_variable? :qwfpgjluy
    first.set_variable :qwfpgjluy, 42, loc
    assert first.has_variable? :qwfpgjluy

    var = first.get_variable :qwfpgjluy
    assert_equal 42, var.value
    assert_same loc, var.location
  end

  def test_reset_variable
    first = SF::Object.new :first

    first.set_variable :qwfpgjluy, 1
    first.set_variable :qwfpgjluy, 42
  end

  def test_reset_variable_incompatible
    first = SF::Object.new :first

    first.set_variable :qwfpgjluy, 42

    error = assert_raises SF::IncompatibleValueError do
      first.set_variable :qwfpgjluy, "hello"
    end

    assert_equal "incompatible assignation ('integer' to 'string')", error.message
  end

  def test_get_variable_undefined
    first = SF::Object.new :first

    error = assert_raises SF::VariableNotFoundError do
      first.get_variable :qwfpgjluy
    end

    assert_equal "undefined variable 'qwfpgjluy'", error.message
  end

  def test_value_of
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, 42

    assert_equal 42, first.value_of(:qwfpgjluy)
  end

  def test_guess_variable
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum
    first.set_variable :arstdhnei, String

    assert_equal :arstdhnei, first.guess_variable("hello world")
  end

  def test_guess_variable_fail
    first = SF::Object.new :first

    error = assert_raises SF::IncompatibleValueError do
      first.guess_variable 42
    end

    assert_equal "object 'first' has no uninitialized variable compatible with 'integer'", error.message
  end

  def test_guess_initialized_variable
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, 42

    assert_raises SF::IncompatibleValueError do
      first.guess_variable 42
    end
  end

  def test_guess_variable_ambiguous
    first = SF::Object.new :first
    first.set_variable :qwfpgjluy, Fixnum
    first.set_variable :arstdhnei, Fixnum

    error = assert_raises SF::AmbiguousValueError do
      first.guess_variable 42
    end

    assert_equal 'value is ambiguous', error.message
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
    assert first.can_adopt? second
    assert_empty first.children

    first.adopt second

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
    error = assert_raises SF::UnauthorizedChildError do
      first.adopt extra
    end

    dia = diagnostics.shift
    assert_equal :error, dia.level
    assert_equal "object 'first' cannot have more than 2 'second'", dia.message
    assert_same extra.location, dia.location

    assert_equal dia.to_s, error.message
  end

  def test_adopt_unwanted
    first = SF::Object.new :first
    second = SF::Object.new :second

    refute first.can_adopt? second

    error = assert_raises SF::UnauthorizedChildError do
      first.adopt second
    end

    dia = diagnostics.shift
    assert_equal :error, dia.level
    assert_equal "object 'first' cannot have 'second'", dia.message
    assert_same second.location, dia.location

    assert_equal dia.to_s, error.message
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

    second.auto_adopt
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

    assert second.opaque?

    assert_raises SF::UnauthorizedChildError do
      third.auto_adopt
    end

    assert_equal [second], first.children

    diagnostics.shift
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

    third.auto_adopt
    assert_equal [second, third], first.children
  end

  def test_auto_adopt_unwanted
    first = SF::Object.new :first

    error = assert_raises SF::UnauthorizedChildError do
      first.auto_adopt
    end

    dia = diagnostics.shift

    assert_equal :error, dia.level
    assert_equal "object 'first' is not allowed in this context", dia.message
    assert_same first.location, dia.location

    assert_equal dia.to_s, error.message
  end

  def test_block_auto_adopt
    first = SF::Object.new :first
    first.allow_children :second

    second_context = SF::Context.new
    second_context.object = first
    second = SF::Object.new :second, SF::Location.new(second_context)
    second.allow_children :third

    second.block_auto_adopt!
    second.auto_adopt

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

    assert copy.opaque?

    assert_equal 'world', copy.value_of(:hello)
    assert_equal copy.children, original.children
  end

  def test_is_root
    root = SF::Object.new :first
    assert root.root?

    context = SF::Context.new
    context.object = root

    branch = SF::Object.new :second, SF::Location.new(context)
    refute branch.root?
  end

  def test_validate_incomplete
    first = SF::Object.new :first
    first.allow_children :second, min: 2
    first.adopt SF::Object.new(:second)

    error = assert_raises SF::InvalidObjectError do
      first.validate
    end

    dia = diagnostics.shift
    assert_equal :error, dia.level
    assert_equal "object 'first' must have at least 2 'second', got 1", dia.message
    assert_same first.location, dia.location

    assert_equal dia.to_s, error.message
  end

  def test_validate_uninitialized
    first = SF::Object.new :first
    first.set_variable :test, String

    error = assert_raises SF::InvalidObjectError do
      first.validate
    end

    dia1 = diagnostics.shift
    assert_equal :error, dia1.level
    assert_equal "object 'first' has one or more uninitialized variables", dia1.message
    assert_same first.location, dia1.location

    assert_equal dia1.to_s, error.to_s
  end

  def test_inspect
    first = SF::Object.new :first

    assert_equal 'first@<native code>', first.inspect
  end
end
