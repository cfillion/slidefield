require File.expand_path('../helper', __FILE__)

class TestParser < MiniTest::Test
  def test_identifier
    tokens = [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:identifier=>'val'}}
    ]

    expect 'var=val', tokens
    expect 'var = val', tokens
    expect 'var = val  ', tokens
    expect "var\t=\tval", tokens
    expect "var\t=\tval % comment", tokens
    expect "var\t%{%}=%{%}val", tokens
    expect "  var=val", tokens
    expect "\t\tvar=val", tokens
    expect "var=val;", tokens
    expect "var=val;%comment", tokens

    expect 'var+=val', [
      :assignment=>{:variable=>'var', :operator=>'+=', :value=>{:identifier=>'val'}}
    ]
    expect 'var-=val', [
      :assignment=>{:variable=>'var', :operator=>'-=', :value=>{:identifier=>'val'}}
    ]
    expect 'var*=val', [
      :assignment=>{:variable=>'var', :operator=>'*=', :value=>{:identifier=>'val'}}
    ]
    expect 'var/=val', [
      :assignment=>{:variable=>'var', :operator=>'/=', :value=>{:identifier=>'val'}}
    ]
  end

  def test_integer
    expect 'var=42', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:integer=>'42'}}
    ]

    expect 'var=-42', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:integer=>'-42'}}
    ]
  end

  def test_string
    expect 'var="value"', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:string=>'"value"'}}
    ]

    expect 'var="say \"hello\""', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:string=>'"say \\"hello\\""'}}
    ]
  end

  def test_point
    expect 'var=42x24', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:point=>'42x24'}}
    ]

    expect 'var=-42x24', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:point=>'-42x24'}}
    ]

    expect 'var=42x-24', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:point=>'42x-24'}}
    ]
  end

  def test_color
    expect 'var=#C0FF33FF', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:color=>'#C0FF33FF'}}
    ]

    expect 'var=#c0ff33ff', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:color=>'#c0ff33ff'}}
    ]
  end

  def test_boolean
    expect 'var=:true', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:boolean=>':true'}}
    ]

    expect 'var=:false', [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:boolean=>':false'}}
    ]
  end

  def test_converter
    tokens = [
      :assignment=>{:variable=>'var', :operator=>'=', :value=>{:cast=>'converter_name', :identifier=>'val'}}
    ]

    expect 'var=(converter_name)val', tokens
    expect 'var=(converter_name)  val', tokens
    expect 'var= (converter_name)  val', tokens
    expect "var= (converter_name)\t\tval", tokens
    expect "var= (converter_name)%{%}val", tokens
    expect "var= ( converter_name )val", tokens
  end

  def test_object
    expect '\\test', [
      {:object=>{:type=>'test'}}
    ]

    expect '\\TEST', [
      {:object=>{:type=>'TEST'}}
    ]

    expect '\\te_st', [
      {:object=>{:type=>'te_st'}}
    ]

    expect '\\t3s7', [
      {:object=>{:type=>'t3s7'}}
    ]

    tokens = [
      {:object=>{:type=>'test', :body=>[]}}
    ]

    expect '\\test{}', tokens
    expect '\\test { } ', tokens
    expect "\\test\t{\t}\t", tokens
    expect "\\test\n{\n}", tokens
    expect '\\test%{%}{%{%}}', tokens
  end

  def test_object_value
    tokens = [
      {:object=>{:type=>'test', :value=>{:identifier=>'val'}}}
    ]

    expect '\\test val', tokens
    expect "\\test\tval", tokens
    expect "\\test%{%}val", tokens
    assert_raises Parslet::ParseFailed do
      parse "\\test\nval"
    end

    expect '\\test 42', [
      {:object=>{:type=>'test', :value=>{:integer=>'42'}}}
    ]

    expect '\\test4-2', [
      {:object=>{:type=>'test4', :value=>{:integer=>'-2'}}}
    ]

    expect '\\test "string"', [
      {:object=>{:type=>'test', :value=>{:string=>'"string"'}}}
    ]

    expect '\\test 24x42', [
      {:object=>{:type=>'test', :value=>{:point=>'24x42'}}}
    ]

    expect '\\test #FFFFFFFF', [
      {:object=>{:type=>'test', :value=>{:color=>'#FFFFFFFF'}}}
    ]

    expect '\\test :true', [
      {:object=>{:type=>'test', :value=>{:boolean=>':true'}}}
    ]

    expect '\\test (converter)val', [
      {:object=>{:type=>'test', :value=>{:cast=>'converter', :identifier=>'val'}}}
    ]
  end

  def test_object_body
    expect '\\test{\\child;}', [
      {:object=>{:type=>'test', :body=>[
        {:object=>{:type=>'child'}}
      ]}}
    ]

    assert_raises Parslet::ParseFailed do
      parse '\\test{\\child}'
    end

    expect "\\test{\n\t\\child\n}", [
      {:object=>{:type=>'test', :body=>[
        {:object=>{:type=>'child'}}
      ]}}
    ]

    expect "\\test{\n\t\\child { \\subchild; }\n}", [
      {:object=>{:type=>'test', :body=>[
        {:object=>{:type=>'child', :body=>[
          {:object=>{:type=>'subchild'}}
        ]}}
      ]}}
    ]

    expect "\\test{var=val;}", [
      {:object=>{:type=>'test', :body=>[
        {:assignment=>{:variable=>'var', :operator=>'=', :value=>{:identifier=>'val'}}}
      ]}}
    ]

    assert_raises Parslet::ParseFailed do
      parse '\\test{var=val}'
    end
  end

  def test_comments
    assert_raises Parslet::ParseFailed do
      parse "%{"
    end
  end

  def test_separator
    assert_raises Parslet::ParseFailed do
      parse "\\test \\test"
    end

    assert_raises Parslet::ParseFailed do
      parse "life = 42 life = 42"
    end

    parse "\\test; \\test"
    parse "\\test; life = 42"
    parse "life = 42; \\test"
  end

  def expect(input, tokens)
    assert_equal tokens, parse(input)
  end

  def parse(input)
    clean_tokens SlideField::Parser.new.parse(input)
  end

  def clean_tokens(tokens)
    case tokens
    when Array
      tokens.collect {|e|
        clean_tokens e
      }
    when Hash
      tokens.merge(tokens) {|k,e|
        clean_tokens e
      }
    when Parslet::Slice
      tokens.to_s
    end
  end
end
