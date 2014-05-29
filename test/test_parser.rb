require File.expand_path('../helper', __FILE__)

class TestParser < MiniTest::Test
  def test_variables
    input = <<-SFP
name="value"
name =\t"";
name += 1
\x20\tname-= 1x23
name *= "value"
name /= #FFFFFFFF
name2 = name\t\x20
name = 1;\x20\tname = 2
name\t\t= -3
name =    :true
name = :false
name =\t(cast)"value"
name = (auto) 42
    SFP

    tokens = [
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:string=>'"value"'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:string=>'""'}}},
      {:assignment=>{:variable=>'name', :operator=>'+=', :value=>{:integer=>'1'}}},
      {:assignment=>{:variable=>'name', :operator=>'-=', :value=>{:point=>'1x23'}}},
      {:assignment=>{:variable=>'name', :operator=>'*=', :value=>{:string=>'"value"'}}},
      {:assignment=>{:variable=>'name', :operator=>'/=', :value=>{:color=>'#FFFFFFFF'}}},
      {:assignment=>{:variable=>'name2', :operator=>'=', :value=>{:identifier=>'name'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:integer=>'1'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:integer=>'2'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:integer=>'-3'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:boolean=>':true'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:boolean=>':false'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:cast=>'cast', :string=>'"value"'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:cast=>'auto', :integer=>'42'}}},
    ]

    assert_equal tokens, parse(input)
  end

  def test_objects
    input = <<-SFP
\\test
\x20\t\\test;
\\test{}
\\test {\t}\x20\t
\\test 42
\\test 42{}
\\test "hello"{}
\\test 12x3{}
\\test 1 {
var=1
  var = 2
}
\\test {
\\test
}
\\test1; \\test2
\\test3-3
    SFP

    tokens = [
      {:object=>{:type=>'test'}},
      {:object=>{:type=>'test'}},
      {:object=>{:type=>'test', :body=>[]}},
      {:object=>{:type=>'test', :body=>[]}},
      {:object=>{:type=>'test', :value=>{:integer=>'42'}}},
      {:object=>{:type=>'test', :value=>{:integer=>'42'}, :body=>[]}},
      {:object=>{:type=>'test', :value=>{:string=>'"hello"'}, :body=>[]}},
      {:object=>{:type=>'test', :value=>{:point=>'12x3'}, :body=>[]}},
      {:object=>{:type=>'test', :value=>{:integer=>'1'}, :body=>[
        {:assignment=>{:variable=>'var', :operator=>'=', :value=>{:integer=>'1'}}},
        {:assignment=>{:variable=>'var', :operator=>'=', :value=>{:integer=>'2'}}},
      ]}},
      {:object=>{:type=>'test', :body=>[
        {:object=>{:type=>'test'}},
      ]}},
      {:object=>{:type=>'test1'}},
      {:object=>{:type=>'test2'}},
      {:object=>{:type=>'test3', :value=>{:integer=>'-3'}}},
    ]

    assert_equal tokens, parse(input)
  end

  def test_comments
    input = <<-SFP
% hello world
%{%}
name="value" % comment
\\test %comment \\test
%{
multi line
comment
%}\\test %test
\t{}
\\test %{test%} %{test%} 42 %{test%}%{test%}%test
{}
name%{%}=%{%}"value"
name%{%}=%{%}(cast)%{%}"value"
% bye bye
    SFP

    tokens = [
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:string=>'"value"'}}},
      {:object=>{:type=>'test'}},
      {:object=>{:type=>'test', :body=>[]}},
      {:object=>{:type=>'test', :value=>{:integer=>"42"}, :body=>[]}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:string=>'"value"'}}},
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:cast=>'cast', :string=>'"value"'}}},
    ]

    assert_equal tokens, parse(input)
  end

  def test_escaped_quote
    input = <<-SFP
name="hello \\"world\\""
    SFP

    tokens = [
      {:assignment=>{:variable=>'name', :operator=>'=', :value=>{:string=>'"hello \\"world\\""'}}},
    ]

    assert_equal tokens, parse(input)
  end

  def test_no_trailing_newline
    parse "\\test"
    parse "\\test{}"
    parse "\\test 1"
    parse "var = 1"
    parse "% nothing"
    parse "%{ nothing %}"
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
