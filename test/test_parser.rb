require File.expand_path('../helper', __FILE__)

class TestParser < MiniTest::Test
  def test_var_identifier
    tokens = [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :identifier=>'val'}
      }
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
      :assignment=>{
        :variable=>'var',
        :operator=>'+=',
        :value=>{:filters=>[], :identifier=>'val'}
      }
    ]
    expect 'var-=val', [
      :assignment=>{
        :variable=>'var',
        :operator=>'-=',
        :value=>{:filters=>[], :identifier=>'val'}
      }
    ]
    expect 'var*=val', [
      :assignment=>{
        :variable=>'var',
        :operator=>'*=',
        :value=>{:filters=>[], :identifier=>'val'}
      }
    ]
    expect 'var/=val', [
      :assignment=>{
        :variable=>'var',
        :operator=>'/=',
        :value=>{:filters=>[], :identifier=>'val'}
      }
    ]
  end

  def test_var_integer
    expect 'var=42', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :integer=>'42'}
      }
    ]

    expect 'var=-42', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :integer=>'-42'}
      }
    ]
  end

  def test_var_string
    expect 'var="value"', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :string=>'"value"'}
      }
    ]

    expect 'var="say \"hello\""', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :string=>'"say \\"hello\\""'}
      }
    ]
  end

  def test_var_point
    expect 'var=42x24', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :point=>'42x24'}
      }
    ]

    expect 'var=-42x24', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :point=>'-42x24'}
      }
    ]

    expect 'var=42x-24', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :point=>'42x-24'}
      }
    ]
  end

  def test_var_color
    expect 'var=#C0FF33FF', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :color=>'#C0FF33FF'}
      }
    ]

    expect 'var=#c0ff33ff', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :color=>'#c0ff33ff'}
      }
    ]
  end

  def test_var_boolean
    expect 'var=:true', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :boolean=>':true'}
      }
    ]

    expect 'var=:false', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :boolean=>':false'}
      }
    ]
  end

  def test_var_object
    expect 'var=\\test', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :object=>{:type=>'test'}}
      }
    ]

    expect 'var=\\test {}', [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{:filters=>[], :object=>{:type=>'test', :body=>[]}}
      }
    ]

    expect "var=\\test {\n\tvar=val\n}", [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{
          :filters=>[],
          :object=>{:type=>'test', :body=>[
            {:assignment=>{
              :variable=>'var',
              :operator=>'=',
              :value=>{:filters=>[], :identifier=>'val'}}
            }
          ]}
        }
      }
    ]
  end

  def test_filter
    tokens = [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{
          :filters=>[{:name=>'filter_name'}],
          :identifier=>'val'
        }
      }
    ]

    expect 'var=(filter_name)val', tokens
    expect 'var=(filter_name)  val', tokens
    expect 'var= (filter_name)  val', tokens
    expect "var= (filter_name)\t\tval", tokens
    expect "var= (filter_name)%{%}val", tokens
    expect "var= ( filter_name )val", tokens

    tokens = [
      :assignment=>{
        :variable=>'var',
        :operator=>'=',
        :value=>{
          :filters=>[{:name=>'first'}, {:name=>'second'}],
          :identifier=>'val'
        }
      }
    ]

    expect "var=(first)(second)val", tokens
    expect "var=(first) (second)val", tokens
  end

  def test_object
    expect '\\test', [
      {:object=>{:type=>'test'}}
    ]

    expect '\\test % comment', [
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
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[], :identifier=>'val'}
      }}
    ]

    expect '\\test val', tokens
    expect "\\test\tval", tokens
    expect "\\test%{%}val", tokens
    assert_raises Parslet::ParseFailed do
      parse "\\test\nval"
    end

    expect '\\test 42', [
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[], :integer=>'42'}
      }}
    ]

    expect '\\test4-2', [
      {:object=>{
        :type=>'test4',
        :value=>{:filters=>[], :integer=>'-2'}
      }}
    ]

    expect '\\test "string"', [
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[], :string=>'"string"'}
      }}
    ]

    expect '\\test 24x42', [
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[], :point=>'24x42'}
      }}
    ]

    expect '\\test #FFFFFFFF', [
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[], :color=>'#FFFFFFFF'}
      }}
    ]

    expect '\\test :true', [
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[], :boolean=>':true'}
      }}
    ]

    expect '\\test (filter)val', [
      {:object=>{
        :type=>'test',
        :value=>{:filters=>[{:name=>'filter'}], :identifier=>'val'}
      }}
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
        {:assignment=>{
          :variable=>'var',
          :operator=>'=',
          :value=>{:filters=>[], :identifier=>'val'}}
        }
      ]}}
    ]

    assert_raises Parslet::ParseFailed do
      parse '\\test{var=val}'
    end
  end

  def test_template
    expect '\\&test', [
      {:object=>{:template=>'&', :type=>'test'}}
    ]
  end

  def test_comments
    assert_raises Parslet::ParseFailed do
      parse "%{"
    end
  end

  def test_separator
    assert_raises Parslet::ParseFailed do
      parse "life = 42 life = 42"
    end

    expect "\\test; \\test", [
      {:object=>{:type=>'test'}},
      {:object=>{:type=>'test'}}
    ]

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
