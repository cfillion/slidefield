require File.expand_path('../helper', __FILE__)

module SlideField::ObjectRules
  class Parent < Base
    def rules
      child :child
      child :value
      child :aaaa
    end
  end

  class Child < Base
  end

  class Type < Base
    def rules
      property :test, :point, [0,0]
    end
  end

  class Value < Base
    def rules
      property :num, :integer, 0
      property :num2, :integer, 0
      property :str, :string, ""
    end
  end

  class Picky < Base
    def rules
      property :king_name, :string
      child :minOne, 1
      child :minTwo, 2
      child :maxOne, 1, 1
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

    assert_match /\A\[input\] /, error.message
    refute_match /\A\[input\] \[input\]/, error.message
    assert_match /\n\t"\n\t\^\Z/, error.message
  end

  def test_run_interpreter_error
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.run_string "\\object\n"
    end

    assert_match /\A\[input\] /, error.message
    assert_match /\n\t\\object\n\t \^\Z/, error.message
  end

  def test_run_interpreter_validation
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.run_string "% nothing\n"
    end

    assert_match /\A\[input\] /, error.message
    assert_match /line 0 char 0\Z/, error.message
  end

  def test_empty_tree
    o = SlideField::ObjectData.new :parent, 'loc'
    SlideField::Interpreter.new.interpret_tree "", o
  end

  def test_unsupported_object
    tokens = [
      {:object=>{:type=>slice('aaaa', 1)}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unsupported object 'aaaa'", error.message
  end

  def test_unsupported_statement
    tokens = [
      {:hello_world=>{}},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unsupported statement 'hello_world'", error.message
  end

  def test_unsupported_type
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :dog_food=>slice('yum', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unsupported type 'dog_food' at line 1 char 3", error.message
  end

  def test_unsupported_operator
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('baconize', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unsupported operator 'baconize' at line 1 char 2", error.message
  end

  def test_set_already_defined
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 1

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Variable 'var' is already defined at line 1 char 1", error.message
  end

  def test_set_integer
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal 42, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_point
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :point=>slice('12x34', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal [12,34], o.get(:var)
    assert_equal :point, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_string
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :string=>slice('"hello"', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal 'hello', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_color
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :color=>slice('#C0FF33FF', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal [192, 255, 51, 255], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_boolean
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :boolean=>slice(':true', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal true, o.get(:var)
    assert_equal :boolean, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_object
    object = {
      :type=>slice('type', 2),
      :value=>{:filters=>[], :point=>slice('42x42', 2)}
    }

    tokens = [{
      :assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :object=>object}
      }
    }]

    o = SlideField::ObjectData.new :child, 'loc'
    o.include_path = 'include/path/'
    o.context = 'the/file.sfp'

    SlideField::Interpreter.new.interpret_tree tokens, o
    val = o.get(:var)

    assert_equal object, o.get(:var)
    assert_equal :object, o.var_type(:var)
    assert_equal 'line 2 char 1', o.var_loc(:var)
  end

  def test_set_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :test, 'hello', 'loc', :string

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 'hello', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_set_undefined_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Undefined variable 'test' at line 1 char 3", error.message
  end


  def test_set_wrong_type
    tokens = [
      {:assignment=>{
        :variable=>slice('test', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :type, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'integer', expecting 'point' for property 'test' at line 1 char 3", error.message
  end

  def test_add_undefined
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Undefined variable 'var' at line 1 char 1", error.message
  end

  def test_add_incompatible
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'integer', expecting 'string' for variable or property 'var' at line 1 char 3", error.message
  end

  def test_add_integer
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 42, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 84, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_point
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :point=>slice('42x42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [42,42], 'loc', :point

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [84,84], o.get(:var)
    assert_equal :point, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_string
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :string=>slice('" world"', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello', 'loc', :string

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 'hello world', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_color
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :color=>slice('#01010101', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [0, 0, 0, 0], 'loc', :color

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [1, 1, 1, 1], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_color_overflow
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :color=>slice('#01010101', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [255, 255, 255, 255], 'loc', :color

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [255, 255, 255, 255], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_add_boolean
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :boolean=>slice(':true', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, true, 'loc', :boolean

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '+=' for type 'boolean' at line 1 char 2", error.message
  end

  def test_add_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('+=', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello', 'loc', :string
    o.set :test, ' world', 'loc', :string

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 'hello world', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_undefined
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Undefined variable 'var' at line 1 char 1", error.message
  end

  def test_sub_incompatible
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'integer', expecting 'string' for variable or property 'var' at line 1 char 3", error.message
  end

  def test_sub_integer
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 44, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 2, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_point
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :point=>slice('42x42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [46,44], 'loc', :point

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [4,2], o.get(:var)
    assert_equal :point, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_string
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :string=>slice('" world"', 1)}
      }},
      {:assignment=>{
        :variable=>slice('var', 2),
        :operator=>slice('-=', 2),
        :value=>{:filters=>[], :string=>slice('"test"', 2)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello world', 'loc', :string

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 'hello', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 2 char 3', o.var_loc(:var)
  end

  def test_sub_color
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :color=>slice('#01010101', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [1, 1, 1, 1], 'loc', :color

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [0, 0, 0, 0], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_color_underflow
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :color=>slice('#01010101', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [0, 0, 0, 0], 'loc', :color

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [0, 0, 0, 0], o.get(:var)
    assert_equal :color, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_sub_boolean
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :boolean=>slice(':true', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, true, 'loc', :boolean

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '-=' for type 'boolean' at line 1 char 2", error.message
  end

  def test_sub_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('-=', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 3, 'loc', :integer
    o.set :test, 2, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 1, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_mul_undefined
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Undefined variable 'var' at line 1 char 1", error.message
  end

  def test_mul_incompatible
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'integer', expecting 'string' for variable or property 'var' at line 1 char 3", error.message
  end

  def test_mul_integer
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :integer=>slice('4', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 4, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 16, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_mul_point
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :point=>slice('4x2', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [4,2], 'loc', :point

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [16,4], o.get(:var)
    assert_equal :point, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_mul_string
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :string=>slice('"3"', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 'testtesttest', o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_mul_string_invalid
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :string=>slice('"aaaa"', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid string multiplier 'aaaa', integer > 0 required at line 1 char 3", error.message
  end

  def test_mul_color
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :color=>slice('#02020202', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [4, 4, 4, 4], 'loc', :color

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '*=' for type 'color' at line 1 char 2", error.message
  end

  def test_mul_boolean
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :boolean=>slice(':true', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, true, 'loc', :boolean

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '*=' for type 'boolean' at line 1 char 2", error.message
  end

  def test_mul_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('*=', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 3, 'loc', :integer
    o.set :test, 2, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 6, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_div_undefined
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Undefined variable 'var' at line 1 char 1", error.message
  end

  def test_div_incompatible
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'test', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'integer', expecting 'string' for variable or property 'var' at line 1 char 3", error.message
  end

  def test_div_integer
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :integer=>slice('2', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 7, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 3, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_div_integer_by_zero
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :integer=>slice('0', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 42, 'loc', :integer

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "divided by zero at line 1 char 3", error.message
  end

  def test_div_point
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :point=>slice('2x3', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [7,42], 'loc', :point

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal [3,14], o.get(:var)
    assert_equal :point, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_div_point_by_zero
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :point=>slice('2x0', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [42,42], 'loc', :point

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "divided by zero at line 1 char 3", error.message
  end

  def test_div_string
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :string=>slice('" world"', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 'hello world', 'loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '/=' for type 'string' at line 1 char 2", error.message
  end

  def test_div_color
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :color=>slice('#02020202', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, [4, 4, 4, 4], 'loc', :color

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '/=' for type 'color' at line 1 char 2", error.message
  end

  def test_div_boolean
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :boolean=>slice(':true', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, true, 'loc', :boolean

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid operator '/=' for type 'boolean' at line 1 char 2", error.message
  end

  def test_div_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('/=', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :var, 6, 'loc', :integer
    o.set :test, 2, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 3, o.get(:var)
    assert_equal :integer, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_children
    tokens = [
      {:object=>{:type=>slice('child', 1), :body=>[
        {:assignment=>{
          :variable=>slice('var', 1),
          :operator=>slice('=', 1),
          :value=>{:filters=>[], :identifier=>slice('parent_var', 1)}
        }},
      ]}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :parent_var, 'hello', 'loc', :string

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 1, o.children.count
    assert_equal 'hello', o[:child][0].get(:var)
  end

  def test_object_value
    tokens = [
      {:object=>{
        :type=>slice('value', 1),
        :value=>{:filters=>[], :integer=>slice('42', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 1, o.children.count
    assert_equal 42, o[:value][0].get(:num)
  end

  def test_object_identifier_value
    tokens = [
      {:object=>{
        :type=>slice('value', 1),
        :value=>{:filters=>[], :identifier=>slice('test', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :test, 42, 'loc', :integer

    SlideField::Interpreter.new.interpret_tree tokens, o
    assert_equal 1, o.children.count
    assert_equal 42, o[:value][0].get(:num)
  end

  def test_object_invalid_value
    tokens = [
      {:object=>{
        :type=>slice('value', 1),
        :value=>{:filters=>[], :point=>slice('12x3', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'point', expecting one of [:integer, :string] at line 1 char 2", error.message
  end

  def test_unknown_object
    tokens = [
      {:object=>{:type=>slice('qwfpgjluy', 1)}},
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected object 'qwfpgjluy', expecting one of [:child, :value, :aaaa] at line 1 char 1", error.message
  end

  def test_missing_variable
    o = SlideField::ObjectData.new :picky, 'location'

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree [], o
    end

    assert_equal "Missing property 'king_name' for object 'picky' at location", error.message
  end

  def test_missing_child
    o = SlideField::ObjectData.new :picky, 'location'
    o.set :king_name, 'value', 'var loc', :string

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree [], o
    end

    assert_equal "Object 'picky' must have at least 1 'minOne', 0 found at location", error.message

    c1 = SlideField::ObjectData.new :minOne, 'location'
    o << c1

    c2 = SlideField::ObjectData.new :minTwo, 'location'
    o << c2

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree [], o
    end

    assert_equal "Object 'picky' must have at least 2 'minTwo', 1 found at location", error.message
  end

  def test_child_overdose
    o = SlideField::ObjectData.new :picky, 'location'
    o.set :king_name, 'value', 'var loc', :string

    c1 = SlideField::ObjectData.new :minOne, 'location'
    o << c1

    c2 = SlideField::ObjectData.new :minTwo, 'location'
    o << c2
    o << c2

    c3 = SlideField::ObjectData.new :maxOne, 'location'
    o << c3
    o << c3

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree [], o
    end

    assert_equal "Object 'picky' can not have more than 1 'maxOne', 2 found at location", error.message
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
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{:filters=>[], :string=>slice('"\\\\ \\"\\n\\s"', 1)}
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal "\\ \"\ns", o.get(:var)
    assert_equal :string, o.var_type(:var)
    assert_equal 'line 1 char 3', o.var_loc(:var)
  end

  def test_default_value
    o = SlideField::ObjectData.new :type, 'loc'
    SlideField::Interpreter.new.interpret_tree [], o

    assert_equal [0,0], o.get(:test)
    assert_equal :point, o.var_type(:test)
    assert_equal 'default', o.var_loc(:test)
  end

  def test_default_value_parent
    p = SlideField::ObjectData.new :type, 'loc'
    p.set :test, [1,1], 'loc', :point

    o = SlideField::ObjectData.new :type, 'loc'
    o.parent = p

    SlideField::Interpreter.new.interpret_tree [], o

    assert_equal [1,1], o.get(:test)
    assert_equal :point, o.var_type(:test)
    assert_equal 'loc', o.var_loc(:test)
  end

  def test_template
    tokens = [{
      :object=>{:template=>slice('&', 1), :type=>slice('var_name', 1)}
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, {:type=>slice('child', 2)}, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal 1, o[:child].count
    assert_equal 'line 1 char 2', o[:child].first.loc
  end

  def test_template_upstream_body
    template = {
      :type=>slice('child', 1),
      :body=>[
        {:assignment=>{
          :variable=>slice('var', 1),
          :operator=>slice('=', 1),
          :value=>{:filters=>[], :integer=>slice('42', 1)}
        }},
      ]
    }

    tokens = [{
      :object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
      }
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o
    copy = o[:child].first

    assert_equal 42, copy.get(:var)
    assert_equal :integer, copy.var_type(:var)
    assert_equal 'line 2 char 1', copy.var_loc(:var)
  end

  def test_template_downstream_body
    template = {
      :type=>slice('child', 1),
    }

    tokens = [{
      :object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
        :body=>[
          {:assignment=>{
            :variable=>slice('var', 3),
            :operator=>slice('=', 3),
            :value=>{:filters=>[], :integer=>slice('42', 3)}
          }},
        ]
      }
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o
    copy = o[:child].first

    assert_equal 42, copy.get(:var)
    assert_equal :integer, copy.var_type(:var)
    assert_equal 'line 3 char 3', copy.var_loc(:var)
  end

  def test_template_merge_bodies
    template = {
      :type=>slice('child', 1),
      :body=>[
        {:assignment=>{
          :variable=>slice('var', 1),
          :operator=>slice('+=', 1),
          :value=>{:filters=>[], :integer=>slice('2', 1)}
        }},
      ]
    }

    tokens = [{
      :object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
        :body=>[
          {:assignment=>{
            :variable=>slice('var', 3),
            :operator=>slice('=', 3),
            :value=>{:filters=>[], :integer=>slice('42', 3)}
          }},
        ]
      }
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o
    copy = o[:child].first

    assert_equal 44, copy.get(:var)
    assert_equal :integer, copy.var_type(:var)
    assert_equal 'line 2 char 1', copy.var_loc(:var)
  end

  def test_template_upstream_value
    template = {
      :type=>slice('value', 1),
      :value=>{:filters=>[], :integer=>slice('42', 1)}
    }

    tokens = [{
      :object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
      }
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o
    copy = o[:value].first

    assert_equal 42, copy.get(:num)
    assert_equal :integer, copy.var_type(:num)
    assert_equal 'line 2 char 1', copy.var_loc(:num)
  end

  def test_template_downstream_value
    template = {
      :type=>slice('value', 1),
    }

    tokens = [{
      :object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
        :value=>{:filters=>[], :integer=>slice('42', 2)}
      }
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o
    copy = o[:value].first

    assert_equal 42, copy.get(:num)
    assert_equal :integer, copy.var_type(:num)
    assert_equal 'line 2 char 3', copy.var_loc(:num)
  end

  def test_template_double_value
    template = {
      :type=>slice('value', 1),
      :value=>{:filters=>[], :integer=>slice('42', 1)}
    }

    tokens = [{
      :object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
        :value=>{:filters=>[], :integer=>slice('42', 2)}
      }
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Variable 'num' is already defined at line 2 char 3", error.message
  end

  def test_undefined_template
    tokens = [{
      :object=>{:template=>slice('&', 1), :type=>slice('var_name', 1)}
    }]

    o = SlideField::ObjectData.new :parent, 'loc'

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Undefined variable 'var_name' at line 1 char 2", error.message
  end

  def test_invalid_template
    tokens = [{
      :object=>{:template=>slice('&', 1), :type=>slice('var_name', 1)}
    }]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, 42, 'loc', :integer

    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Unexpected 'integer', expecting 'object' at line 1 char 2", error.message
  end

  def test_filter_point_x
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('x', 1)}],
          :point=>slice('12x34', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :integer, o.var_type(:var)
    assert_equal 12, o.get(:var)
    assert_equal 'line 1 char 4', o.var_loc(:var)
  end

  def test_filter_point_y
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('y', 1)}],
          :point=>slice('12x34', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :integer, o.var_type(:var)
    assert_equal 34, o.get(:var)
    assert_equal 'line 1 char 4', o.var_loc(:var)
  end

  def test_filter_integer_x
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('x', 1)}],
          :integer=>slice('1', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :point, o.var_type(:var)
    assert_equal [1,0], o.get(:var)
    assert_equal 'line 1 char 4', o.var_loc(:var)
  end

  def test_filter_integer_y
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('y', 1)}],
          :integer=>slice('1', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :point, o.var_type(:var)
    assert_equal [0,1], o.get(:var)
    assert_equal 'line 1 char 4', o.var_loc(:var)
  end

  def test_filter_string_lines
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('lines', 1)}],
          :string=>slice('first\\nsecond', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :integer, o.var_type(:var)
    assert_equal 2, o.get(:var)
    assert_equal 'line 1 char 4', o.var_loc(:var)
  end

  def test_filters_order
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[
            {:name=>slice('y', 1)},
            {:name=>slice('x', 1)}
          ],
          :point=>slice('42x24', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :point, o.var_type(:var)
    assert_equal [0,42], o.get(:var)
    assert_equal 'line 1 char 5', o.var_loc(:var)
  end

  def test_filter_identifier
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('x', 1)}],
          :identifier=>slice('test', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.set :test, [12,21], 'loc', :point

    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal :integer, o.var_type(:var)
    assert_equal 12, o.get(:var)
    assert_equal 'line 1 char 4', o.var_loc(:var)
  end

  def test_unknown_filter
    tokens = [
      {:assignment=>{
        :variable=>slice('var', 1),
        :operator=>slice('=', 1),
        :value=>{
          :filters=>[{:name=>slice('aaaa', 1)}],
          :integer=>slice('1', 1)
        }
      }},
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    error = assert_raises SlideField::InterpreterError do
      SlideField::Interpreter.new.interpret_tree tokens, o
    end

    assert_equal "Invalid filter 'aaaa' for type 'integer' at line 1 char 3", error.message
  end

  def test_filter_lost_in_template
    template = {
      :type=>slice('child', 1),
      :body=>[
        {:assignment=>{
          :variable=>slice('var', 1),
          :operator=>slice('=', 1),
          :value=>{
            :filters=>[{:name=>slice('x', 1)}],
            :point=>slice('1x1', 1)
          }
        }},
      ]
    }

    tokens = [
      {:object=>{
        :template=>slice('&', 2),
        :type=>slice('var_name', 2),
      }},
      {:object=>{
        :template=>slice('&', 3),
        :type=>slice('var_name', 3),
      }}
    ]

    o = SlideField::ObjectData.new :parent, 'loc'
    o.set :var_name, template, 'loc', :object

    SlideField::Interpreter.new.interpret_tree tokens, o

    assert_equal 2, o[:child].count

    first = o[:child][0]
    second = o[:child][1]

    assert_equal :integer, first.var_type(:var)
    assert_equal 1, first.get(:var)
    assert_equal 'line 2 char 1', first.var_loc(:var)

    assert_equal :integer, second.var_type(:var)
    assert_equal 1, second.get(:var)
    assert_equal 'line 3 char 1', second.var_loc(:var)
  end

  def test_debug
    tokens = [
      {:object=>{
        :type=>slice('debug', 1),
        :value=>{:filters=>[], :string=>slice('"i haz bugs"', 1)}
      }}
    ]

    o = SlideField::ObjectData.new :child, 'loc'
    o.context = 'parent context'

    pretty, err = capture_io do
      ap :type=>:string, :location=>'line 1 char 2', :value=>'i haz bugs'
    end

    assert_output "DEBUG in local context at line 1 char 1:\n#{pretty}\n" do
      SlideField::Interpreter.new.interpret_tree tokens, o, nil, 'local context'
    end

    assert_empty o[:debug]
  end

  def slice(val, line)
    @col_cache[line] = 0 unless @col_cache[line]
    col = @col_cache[line] += 1

    line_cache = MiniTest::Mock.new
    line_cache.expect :line_and_column, [line, col], [Object]

    pos = Parslet::Position.new val, 0
    Parslet::Slice.new pos, val, line_cache
  end
end
