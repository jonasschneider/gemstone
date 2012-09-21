require 'gemstone'

describe Gemstone::Transformations::UnwindStack do
  it "can unwind nested kernel calls" do
    r = described_class.apply [:kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "returnstr"], [:pi_lit_str, "Stackstring"]]]]]
    r.should == [
      [:ps_push],
      [:ps_push],

      [:ps_pusharg, [:pi_lit_str, "Stackstring"]],
      [:ps_pusharg, [:pi_lit_str, "returnstr"]],
      [:ps_kernel_dispatch],

      [:ps_pop],

      [:ps_pusharg, [:pi_get_inner_res]],
      [:ps_pusharg, [:pi_lit_str, "puts"]],
      [:ps_kernel_dispatch],

      [:ps_pop]
    ]
  end

  it "can unwind a :send to an object" do
    r = described_class.apply [
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [[:pi_lit_str, "my message"]]
          ]
    r.should == [
      [:ps_push],

      [:ps_pusharg, [:pi_lit_str, "my message"]],

      [:ps_push],
      [:ps_pusharg, [:pi_lit_str, "mystr"]],
      [:ps_pusharg, [:pi_lit_str, "lvar_get"]],
      [:ps_kernel_dispatch],
      [:ps_pop],
      [:ps_pusharg, [:pi_get_inner_res]],

      [:ps_init_lscope],
      
      [:ps_object_dispatch],
      
      [:ps_pop]
    ]
  end
end