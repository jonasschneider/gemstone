require 'gemstone'

describe Gemstone::Parser do
  it "parses a hello world" do
    code = "Gemstone.primitive :ps_hello_world"
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
end