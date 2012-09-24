require 'env'

describe Gemstone::Parser do
  it "parses a hello world" do
    code = "Gemstone.primitive :ps_hello_world"
    described_class.parse(code).should == [:pb_block, [:ps_hello_world]]
  end

  it "ignores comments" do
    code = "#my comment\nGemstone.primitive :ps_hello_world\n\n#another comment"
    described_class.parse(code).should == [:pb_block, [:ps_hello_world]]
  end

  it "parses two hello worlds" do
    code = "Gemstone.primitive :ps_hello_world\nGemstone.primitive :ps_hello_world"
    described_class.parse(code).should == [:pb_block, [:ps_hello_world], [:ps_hello_world]]
  end

  it "parses other primitives" do
    code = "Gemstone.primitive :other_prim"
    described_class.parse(code).should == [:pb_block, [:other_prim]]
  end

  it "parses setting & getting lvars" do
    code = "checker = 'first value'\nputs checker"
    described_class.parse(code).should eq([:pb_block, 
      [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "checker"], [:pi_lit_str, "first value"]]],
      [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "checker"]]]]]
    ])
  end
  
  it "parses defining a method on a string" do
    code = "def a.hello\nGemstone.primitive :ps_hello_world\nend"

    described_class.parse(code).should eq([:pb_block, 
      [:send,
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "a"]]],
          [
            [:pi_lit_str, "define_method"],
            [:pi_lit_str, "hello"],
            [:ps_push_lambda, [:pb_block,
              [:ps_hello_world]
            ]]
          ]
        ]
    ])
  end

  it "parses calling a method of a string"
end