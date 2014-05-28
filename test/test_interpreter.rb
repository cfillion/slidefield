require File.expand_path('../helper', __FILE__)

module SlideField::ObjectRules
  class Parent < Base
    def rules
      child :child
      child :value
    end
  end

  class Child < Base
  end

  class Type < Base
    def rules
      variable :test, :size, [0,0]
    end
  end

  class Value < Base
    def rules
      variable :num, :number, 0
      variable :num2, :number, 0
      variable :str, :string, ""
    end
  end

  class Picky < Base
    def rules
      variable :king_name, :string
      child :superchild, true
    end
  end
end

class TestInterpreter < MiniTest::Test
  def setup
    @col_cache = []
  end

  def test_run_parser_error
    error = assert_raises SlideField::ParseError do
      SlideField::Interpreter.new.run_string '"'
    end

    assert_match /^\[input\] /, error.message
  end

  def test_run_interpreter_error
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.run_string "% nothing\n"
    end

    assert_match /^\[input\] /, error.message
  end

  def test_empty_tree
    o = SlideField::ObjectData.new :parent, 'loc'
    SlideField::Interpreter.new.extract_tree "", o
  end

  def test_unsupported_object
    o = SlideField::ObjectData.new :qwfpgjluy, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree({}, o)
    end

    assert_equal "Unsupported object 'qwfpgjluy'", error.message
  end

  def test_unsupported_statement
    tokens = [
      {:hello_world=>{}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unsupported statement 'hello_world'", error.message
  end

  def test_unsupported_type
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:dog_food=>slice('yum', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unsupported type 'dog_food'", error.message
  end

  def test_unsupported_operator
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('baconize', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unsupported operator 'baconize' at line 1 char 2", error.message
  end

  def test_set_already_defined
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 1

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Variable 'var' is already defined at line 1 char 1", error.message
  end

  def test_set_number
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.extract_tree tokens, o

    assert_equal 42, o.get(:var)
    assert_equal :number, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_size
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:size=>slice('12x34', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.extract_tree tokens, o

    assert_equal [12, 34], o.get(:var)
    assert_equal :size, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_string
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:string=>slice('"hello"', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.extract_tree tokens, o

    assert_equal 'hello', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_color
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:color=>slice('#C0FF33FF', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.extract_tree tokens, o

    assert_equal [192, 255, 51, 255], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_boolean
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:boolean=>slice(':true', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.extract_tree tokens, o

    assert_equal true, o.get(:var)
    assert_equal :boolean, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_identifier
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:identifier=>slice('test', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :test, 'hello', 'loc', :string

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 'hello', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_unset_identifier
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:identifier=>slice('test', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Undefined variable 'test' at line 1 char 3", error.message
  end


  def test_set_wrong_type
    tokens = [
      {:assignment=>{:variable=>slice('test', 1), :operator=>slice('=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :type, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unexpected 'number', expecting 'size' at line 1 char 3", error.message
  end

  def test_add_undefined
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Undefined variable 'var' at line 1 char 1", error.message
  end

  def test_add_incompatible
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unexpected 'number', expecting 'string' at line 1 char 3", error.message
  end

  def test_add_number
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 42, 'loc', :number

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 84, o.get(:var)
    assert_equal :number, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_size
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:size=>slice('42x42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [42, 42], 'loc', :size

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal [84, 84], o.get(:var)
    assert_equal :size, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_string
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:string=>slice('" world"', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello', 'loc', :string

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 'hello world', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_color
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:color=>slice('#01010101', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [0, 0, 0, 0], 'loc', :color

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal [1, 1, 1, 1], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_boolean
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:boolean=>slice(':true', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, true, 'loc', :boolean

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unsupported operator '+=' for type 'boolean' at line 1 char 2", error.message
  end

  def test_add_identifier
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('+=', 1), :value=>{:identifier=>slice('test', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello', 'loc', :string
    o.set :test, ' world', 'loc', :string

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 'hello world', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_undefined
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Undefined variable 'var' at line 1 char 1", error.message
  end

  def test_sub_incompatible
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unexpected 'number', expecting 'string' at line 1 char 3", error.message
  end

  def test_sub_number
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 44, 'loc', :number

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 2, o.get(:var)
    assert_equal :number, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_size
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:size=>slice('42x42', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [46, 44], 'loc', :size

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal [4, 2], o.get(:var)
    assert_equal :size, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_string
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:string=>slice('" world"', 1)}}},
      {:assignment=>{:variable=>slice(:var, 2), :operator=>slice('-=', 2), :value=>{:string=>slice('"test"', 2)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello world', 'loc', :string

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 'hello', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 2 char 3', o.var_loc(:var)
  end

  def test_sub_color
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:color=>slice('#01010101', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [1, 1, 1, 1], 'loc', :color

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal [0, 0, 0, 0], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_boolean
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:boolean=>slice(':true', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, true, 'loc', :boolean

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unsupported operator '-=' for type 'boolean' at line 1 char 2", error.message
  end

  def test_sub_identifier
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('-=', 1), :value=>{:identifier=>slice('test', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 3, 'loc', :number
    o.set :test, 2, 'loc', :number

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 1, o.get(:var)
    assert_equal :number, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_children
    tokens = [
      {:object=>{:type=>slice('child', 1), :body=>[
        {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:identifier=>slice('parent_var', 1)}}},
      ]}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :parent_var, 'hello', 'loc', :string

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 1, o.children.count
    assert_equal 'hello', o[:child][0].get(:var)
  end

  def test_object_value
    tokens = [
      {:object=>{:type=>slice('value', 1), :value=>{:number=>slice('42', 1)}}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 1, o.children.count
    assert_equal 42, o[:value][0].get(:num)
  end

  def test_object_identifier_value
    tokens = [
      {:object=>{:type=>slice('value', 1), :value=>{:identifier=>slice('test', 1)}}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :test, 42, 'loc', :number

    SlideField::Interpreter.new.extract_tree tokens, o
    assert_equal 1, o.children.count
    assert_equal 42, o[:value][0].get(:num)
  end

  def test_object_invalid_value
    tokens = [
      {:object=>{:type=>slice('value', 1), :value=>{:size=>slice('12x3', 1)}}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unexpected 'size', expecting one of [:number, :string] at line 1 char 2", error.message
  end

  def test_unknown_object
    tokens = [
      {:object=>{:type=>slice('qwfpgjluy', 1)}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree tokens, o
    end

    assert_equal "Unexpected object 'qwfpgjluy', expecting one of [:child, :value] at line 1 char 1", error.message
  end

  def test_missing_variable
    o = SlideField::ObjectData.new :picky, 'location'

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree [], o
    end

    assert_equal "Missing property 'king_name' for object 'picky' at location", error.message
  end

  def test_missing_child
    o = SlideField::ObjectData.new :picky, 'location'
    o.set :king_name, 'value', 'var loc', :string
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.extract_tree [], o
    end

    assert_equal "Object 'superchild' not found in 'picky' at location", error.message
  end

  def test_file_not_found
    i = SlideField::Interpreter.new
    error = assert_raises SlideField::InterpreterError do
      i.run_file 'no.entry'
    end

    assert_equal "No such file or directory @ rb_sysopen - no.entry", error.message
  end

  def test_include_not_found
    i = SlideField::Interpreter.new
    error = assert_raises SlideField::InterpreterError do
      i.run_string '\\include "/hello"'
    end

    assert_equal "[input] No such file or directory @ rb_sysopen - /hello", error.message
  end

  def test_escape_sequence
    tokens = [
      {:assignment=>{:variable=>slice(:var, 1), :operator=>slice('=', 1), :value=>{:string=>slice('"\\\\ \\"\\n\\s"', 1)}}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.extract_tree tokens, o

    assert_equal "\\ \"\ns", o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_default_value
    o = SlideField::ObjectData.new :type, 'loc'
    SlideField::Interpreter.new.extract_tree [], o

    assert_equal [0,0], o.get(:test)
    assert_equal :size, o.var_type(:test)
    assert_equal 'default', o.var_loc(:test)
  end

  def test_default_value_parent
    p = SlideField::ObjectData.new :type, 'loc'
    p.set :test, [1,1], 'loc', :size

    o = SlideField::ObjectData.new :type, 'loc'
    o.parent = p

    SlideField::Interpreter.new.extract_tree [], o

    assert_equal [1,1], o.get(:test)
    assert_equal :size, o.var_type(:test)
    assert_equal 'loc', o.var_loc(:test)
  end

  def slice(val, line)
    @col_cache[line] = 0 unless @col_cache[line]
    col = @col_cache[line] += 1

    line_cache = MiniTest::Mock.new
    line_cache.expect :line_and_column, [line, col], [Object]

    pos = Parslet::Position.new val, 0
    Parslet::Slice.new(pos, val, line_cache)
  end
end
