require File.expand_path '../helper', __FILE__

class TestDiagnostic < MiniTest::Test
  def setup
    context = SF::Context.new
    context.label = 'context_label'
    context.source = "\t    \thello world"

    @native_location = SF::Location.new
    @file_location = SF::Location.new(context, 1, 8)
  end

  def test_create
    dia = SF::Diagnostic.new :error, 'hello world', :location

    assert_equal :error, dia.level
    assert_equal 'hello world', dia.message
    assert_equal :location, dia.location
  end

  def test_default_location
    dia = SF::Diagnostic.new :error, 'hello world'

    assert_instance_of SF::Location, dia.location
  end

  def test_highlight_native_code
    dia = SF::Diagnostic.new :level, 'test at <native code>', @native_location

    output = [
      '<native code>:'.bold,
      'level: test at',
      '<native code>'.bold,
    ].join "\x20"

    assert_equal output, dia.format
  end

  def test_highlight_file_location
    dia = SF::Diagnostic.new :level, 'test at my path/file:4:2', @native_location

    output = [
      '<native code>:'.bold,
      'level: test at my',
      'path/file:4:2'.bold,
    ].join "\x20"

    assert_equal output, dia.format
  end

  def test_highlight_error
    dia = SF::Diagnostic.new :error, 'this is an error', @native_location

    output = [
      '<native code>:'.bold,
      'error:'.bold.red,
      'this is an',
      'error'.bold.red,
    ].join "\x20"

    assert_equal output, dia.format
  end

  def test_highlight_warning
    dia = SF::Diagnostic.new :warning, 'this is a warning', @native_location

    output = [
      '<native code>:'.bold,
      'warning:'.bold.yellow,
      'this is a',
      'warning'.bold.yellow,
    ].join "\x20"

    assert_equal output, dia.format
  end

  def test_highlight_debug
    dia = SF::Diagnostic.new :debug, 'debugging things', @native_location

    output = [
      '<native code>:'.bold,
      'debug:'.cyan,
      'debug'.cyan + 'ging things',
    ].join "\x20"

    assert_equal output, dia.format
  end

  def test_excerpt
    dia = SF::Diagnostic.new :level, 'test', @file_location

    lines = [
      "#{'context_label:1:8:'.bold} level: test",
      '  hello world',
      '   ^'.bold.green,
    ]

    assert_equal lines, dia.format.split($/)
  end

  def test_invalid_source
    location = SF::Location.new SF::Context.new
    dia = SF::Diagnostic.new :level, 'message', location

    assert_equal ':0:0: level: message', dia.format
  end

  def test_black_and_white
    dia = SF::Diagnostic.new :error, 'test', @file_location

    lines = [
      'context_label:1:8: error: test',
      '  hello world',
      '   ^',
    ]

    assert_equal lines, dia.format(colors: false).split($/)
  end

  def test_inspect
    dia = SF::Diagnostic.new :error, 'test', @file_location

    output = 'context_label:1:8: error: test'

    assert_equal output, dia.format(colors: false, excerpt: false)
    assert_equal output, dia.inspect
    assert_equal output, dia.to_s
  end

  def test_send_to
    device = StringIO.new

    dia = SF::Diagnostic.new :level, 'message', SF::Location.new
    dia.send_to device

    device.rewind
    assert_equal dia.format(colors: false) + "\n", device.read
  end

  def test_compare
    con1 = SF::Context.new 'label', 1
    loc1 = SF::Location.new con1

    con2 = SF::Context.new 'label', 2
    loc2 = SF::Location.new con2

    control = SF::Diagnostic.new :level, 'message', loc1

    assert_equal control, control
    assert_equal control, SF::Diagnostic.new(:level, 'message', loc2)
    refute_equal control, SF::Diagnostic.new(:level, 'message')
    refute_equal control, SF::Diagnostic.new(:error, 'message', loc1)
    refute_equal control, SF::Diagnostic.new(:level, 'hello', loc1)
  end
end
