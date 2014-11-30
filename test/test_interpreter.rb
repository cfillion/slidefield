require File.expand_path '../helper', __FILE__

SF::Object.define :permissiveRoot do
  allow_children :level1
  allow_children :level2
  allow_children :answer
end

SF::Object.define :restrictiveRoot do
  allow_children :level1, min: 2, max: 2
end

SF::Object.define :level1 do
  transparentize!
  allow_children :level2
end

SF::Object.define :level2 do end

SF::Object.define :answer do
  set_variable :the_answer, Fixnum
end

SF::Object.define :collection do
  set_variable :first, SF::Boolean
  set_variable :second, SF::Boolean
end

class TestInterpreter < MiniTest::Test
  include DoctorHelper

  def diagnostics
    SF::Doctor.bag SF::Interpreter
  end

  def setup
    @interpreter = SF::Interpreter.new
    @should_fail = false

    @resources_path = File.expand_path '../resources', __FILE__
  end

  def should_fail; @should_fail = true end

  def teardown
    assert_equal @should_fail, @interpreter.failed?,
      'The interpreter is not in the expected success/failure state'
  end

  def test_parse_error
    should_fail

    @interpreter.run_string 'a = \\&b'

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'failed to match [a-zA-Z_]', error.message
    refute error.location.native?
    assert_equal [1, 6], error.location.line_and_column
  end

  def test_empty_tree
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string "% nothing\n"
  end

  def test_object
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\level1'

    bag = @interpreter.root.children
    first_child = bag.shift
    assert_empty bag

    assert_instance_of SF::Object, first_child
    assert_equal :level1, first_child.type
    assert_equal [1, 2], first_child.location.line_and_column

    assert first_child.location.context.frozen?
    assert_equal 'input', first_child.location.context.label
    assert_equal Dir.pwd, first_child.location.context.include_path
    assert_equal @interpreter.root, first_child.location.context.object
    assert_equal '\level1', first_child.location.context.source
  end

  def test_subobject_flatten
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\level1 { \level1; }'

    bag = @interpreter.root.children
    first_child = bag.shift
    second_child = bag.shift
    assert_empty bag

    assert_equal :level1, first_child.type
    assert_equal @interpreter.root, first_child.location.context.object

    assert_equal :level1, second_child.type
    assert_equal first_child, second_child.location.context.object
  end

  def test_unknown_object
    should_fail

    @interpreter.run_string '\\aaaa'
  end

  def test_forbidden_object
    should_fail

    @interpreter.run_string '\\permissiveRoot'
  end

  def test_object_value
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\answer 42'

    bag = @interpreter.root.children
    answer = bag.shift
    assert_empty bag

    the_answer = answer.get_variable :the_answer
    assert_equal 42, the_answer.value
    assert_equal [1, 9], the_answer.location.line_and_column
    assert_equal @interpreter.root, the_answer.location.context.object
  end

  def test_object_value_mismatch
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\answer "The Ultimate Question of Life, the Universe, and Everything"'
  end

  def test_object_value_ambiguous
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\\collection :true'
  end

  def test_variables
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    i = 42
    s = "hello"
    p = 4x2
    c = #C0FF33FF
    bt = :true
    bf = :false
    INPUT

    i = @interpreter.root.get_variable :i
    assert_instance_of Fixnum, i.value
    assert_equal 42, i.value
    assert_equal [1, 9], i.location.line_and_column

    s = @interpreter.root.get_variable :s
    assert_instance_of String, s.value
    assert_equal "hello", s.value
    assert_equal [2, 9], s.location.line_and_column

    p = @interpreter.root.get_variable :p
    assert_instance_of SF::Point, p.value
    assert_equal SF::Point.new(4, 2), p.value
    assert_equal [3, 9], p.location.line_and_column

    c = @interpreter.root.get_variable :c
    assert_instance_of SF::Color, c.value
    assert_equal SF::Color.new(192, 255, 51, 255), c.value
    assert_equal [4, 9], c.location.line_and_column

    bt = @interpreter.root.get_variable :bt
    assert_instance_of SF::Boolean, bt.value
    assert_equal SF::Boolean.new(true), bt.value
    assert_equal [5, 10], bt.location.line_and_column

    bf = @interpreter.root.get_variable :bf
    assert_instance_of SF::Boolean, bf.value
    assert_equal SF::Boolean.new(false), bf.value
    assert_equal [6, 10], bf.location.line_and_column
  end

  def test_object_in_variable
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    inherited = "hello"

    obj = \\level1 {
      \\level2
    }
    INPUT

    obj = @interpreter.root.get_variable :obj
    assert_instance_of SF::Object, obj.value
    assert_equal :level1, obj.value.type
    assert_equal 'hello', obj.value.value_of(:inherited)
    assert_equal [3, 12], obj.location.line_and_column

    assert_empty @interpreter.root.children, 'Root is not empty'
  end

  def test_copy_variable
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    original = "hello world"
    copy = original
    INPUT

    copy = @interpreter.root.get_variable :copy

    assert_equal 'hello world', copy.value
    assert_equal [2, 12], copy.location.line_and_column
  end

  def test_copy_variable_not_found
    should_fail

    @interpreter.run_string 'copy = fail'
  end

  def test_copy_uninitialized
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\answer { copy = the_answer; }'
  end

  def test_incompatible_reassignation
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    var = 1
    var = 4x2
    INPUT
  end

  def test_operators
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    var = 1
    var *= 80
    var += 4
    var /= 2
    INPUT

    var = @interpreter.root.get_variable :var
    assert_equal 42, var.value
    assert_equal [4, 12], var.location.line_and_column
  end

  def test_change_undefined
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string 'var += 1'

    assert_equal true, @interpreter.failed?
  end

  def test_escape_sequences
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string 'var = "\\\\hello\nworl\d"'

    assert_equal "\\hello\nworld", @interpreter.root.value_of(:var)
  end

  def test_filter
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string 'var = (x)4x2'

    var = @interpreter.root.get_variable :var
    assert_instance_of Fixnum, var.value
    assert_equal 4, var.value
    assert_equal [1, 10], var.location.line_and_column
  end

  def test_filter_order
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string 'var = (x)(x)(lines)"hello"'

    var = @interpreter.root.get_variable :var
    assert_instance_of Fixnum, var.value
    assert_equal 1, var.value
    assert_equal [1, 20], var.location.line_and_column
  end

  def test_invalid_filter
    should_fail

    @interpreter.run_string 'var = (bad_filter)4x2'
  end

  def test_include
    path = File.join @resources_path, 'define_variable.sfi'

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\include "' + path + '"'

    assert_empty @interpreter.root.children

    var = @interpreter.root.get_variable :var
    assert_equal 42, var.value
    assert_equal [1, 7], var.location.line_and_column

    assert_equal path.sub(Dir.pwd + '/', ''), var.location.context.label
    assert_equal @resources_path, var.location.context.include_path
    assert_equal @interpreter.root, var.location.context.object
    assert_equal "var = 42\n", var.location.context.source
  end

  def test_dynamic_template
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    template = {
      var += 1
    }

    var = 1
    \\&template
    \\&template
    INPUT

    tpl = @interpreter.root.get_variable :template
    assert_instance_of SF::Template, tpl.value
    assert_equal [1, 5], tpl.location.line_and_column

    var = @interpreter.root.get_variable :var
    assert_equal 3, var.value
    assert_equal [2, 14], var.location.line_and_column
  end

  def test_static_template
    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    template = \\level1

    \\&template
    \\&template
    INPUT

    obj = @interpreter.root.get_variable :template
    assert_equal :level1, obj.value.type
    assert_equal [1, 17], obj.location.line_and_column

    bag = @interpreter.root.children

    first = bag.shift
    assert_equal :level1, first.type
    assert_equal [3, 7], first.location.line_and_column

    first = bag.shift
    assert_equal :level1, first.type
    assert_equal [4, 7], first.location.line_and_column

    assert_empty bag
  end

  def test_included_template_context
    path = File.join @resources_path, 'template.sfi'

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    \\include "#{path}"

    \\level1 {
      str = "hello"
      \\&template
    }
    INPUT

    level1 = @interpreter.root.first_child :level1

    str = level1.get_variable :str
    assert_equal 'hello world', str.value

    # local context values:
    assert_equal level1, str.location.context.object

    # external context values:
    assert_equal path.sub(Dir.pwd + '/', ''), str.location.context.label
    assert_equal @resources_path, str.location.context.include_path
    assert_equal File.read(path), str.location.context.source
    assert_equal [2, 10], str.location.line_and_column
  end

  def test_undefined_template
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    \\&test
    INPUT
  end

  def test_not_a_template
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    test = 1
    \\&test
    INPUT

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'not a template or an object (see definition at input:1:12)', error.message
    assert_equal [2, 7], error.location.line_and_column
  end

  def test_deep_context_limit
    should_fail

    path = File.join @resources_path, 'recursive_include.sfi'
    @interpreter.run_string '\include "' + path + '"'

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'context level exceeded maximum depth of 50', error.message
    assert_equal [1, 10], error.location.line_and_column
  end

  def test_continue_on_error
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string <<-INPUT
    top_level = 4
    \\level1 {
      sublevel = #00000000
      sublevel += \\level1
      \\not_executed1
    }
    top_level *= 4
    top_level = "hello"
    \\not_executed2
    INPUT

    assert_equal 16, @interpreter.root.value_of(:top_level)
    assert_equal SF::Color.new(0,0,0,0), @interpreter.root.first_child(:level1).value_of(:sublevel)
  end

  def test_file_not_found
    should_fail

    @interpreter.run_file '404'

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'no such file or directory - 404', error.message
    assert error.location.native?
  end

  def test_include_read_error
    should_fail

    @interpreter.run_string <<-INPUT
    \\include "404"
    \\not_executed
    INPUT

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal "no such file or directory - #{File.join Dir.pwd, '404'}", error.message
    assert_equal [1, 14], error.location.line_and_column
  end

  def test_file_is_directory
    should_fail

    @interpreter.run_file '.'

    error = diagnostics.shift
    assert_equal :error, error.level
    assert_equal 'unreadable file - .', error.message
    assert error.location.native?
  end

  def test_object_validation
    should_fail

    @interpreter.root = SF::Object.new :permissiveRoot
    @interpreter.run_string '\\answer'
  end

  def test_root_validation
    should_fail

    @interpreter.root = SF::Object.new :restrictiveRoot
    @interpreter.run_string '\\level1'
  end
end
