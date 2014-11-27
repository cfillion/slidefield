require File.expand_path '../helper', __FILE__

class TestDiagnostic < MiniTest::Test
  def test_create
    dia = SF::Diagnostic.new :error, 'hello world', :location

    assert_equal :error, dia.level
    assert_equal 'hello world', dia.message
    assert_equal :location, dia.location
  end

  def test_highlight_native_code
    dia = SF::Diagnostic.new :level, 'test at <native code>', SF::Location.new
    assert_equal "#{'<native code>:'.bold} level: test at #{'<native code>'.bold}", dia.to_s
  end

  def test_highlight_file_location
    dia = SF::Diagnostic.new :level, 'test at my path/file:4:2', SF::Location.new
    assert_equal "#{'<native code>:'.bold} level: test at my #{'path/file:4:2'.bold}", dia.to_s
  end

  def test_highlight_error
    dia = SF::Diagnostic.new :error, 'this is an error', SF::Location.new
    assert_equal "#{'<native code>:'.bold} #{'error:'.bold.red} this is an #{'error'.bold.red}", dia.to_s
  end

  def test_highlight_warning
    dia = SF::Diagnostic.new :warning, 'this is a warning', SF::Location.new
    assert_equal "#{'<native code>:'.bold} #{'warning:'.bold.yellow} this is a #{'warning'.bold.yellow}", dia.to_s
  end

  def test_highlight_debug
    dia = SF::Diagnostic.new :debug, 'debugging things', SF::Location.new
    assert_equal "#{'<native code>:'.bold} #{'debug:'.cyan} #{'debug'.cyan}ging things", dia.to_s
  end

  def test_excerpt
    context = SF::Context.new 'context_label', nil, nil, "\t    \thello world"
    dia = SF::Diagnostic.new :label, 'test', SF::Location.new(context, 1, 8)

    assert_equal "#{'context_label:1:8:'.bold} label: test\n  hello world\n  #{' ^'.bold.green}", dia.to_s
  end
end
