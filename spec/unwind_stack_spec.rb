require 'gemstone'

describe Gemstone::Transformations::UnwindStack do
  it "can unwind nested kernel calls" do
    r = described_class.apply [:kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "returnstr"], [:pi_lit_str, "Stackstring"]]]]]
    r.should eq([
      [:ps_pusharg, [:pi_lit_str, "Stackstring"]],
      [:ps_pusharg, [:pi_lit_str, "returnstr"]],
      [:ps_kernel_dispatch],

      [:ps_pusharg, [:pi_get_result]],

      [:ps_pusharg, [:pi_lit_str, "puts"]],
      [:ps_kernel_dispatch]
    ])
  end

  it "can unwind a :send to an object" do
    r = described_class.apply [
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [[:pi_lit_str, "my message"]]
          ]
    r.should eq([
      [:ps_pusharg, [:pi_lit_str, "my message"]],
      [:ps_pusharg, [:pi_lit_str, "mystr"]],
      [:ps_pusharg, [:pi_lit_str, "lvar_get"]],
      [:ps_kernel_dispatch],

      [:ps_pusharg, [:pi_get_result]],

      [:ps_push_with_argstack_as_params],
      [:ps_object_dispatch],
      [:ps_pop]
    ])
  end
end