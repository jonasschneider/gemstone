require 'gemstone'

describe Gemstone::Transformations::UnwindStack do
  it "can unwind nested kernel calls" do
    r = described_class.apply [:kernel, [[:lit_str, "puts"], [:send, :kernel, [[:lit_str, "returnstr"], [:lit_str, "Stackstring"]]]]]
    r.should == [
      [:push],
      [:push],

      [:pusharg, [:lit_str, "Stackstring"]],
      [:pusharg, [:lit_str, "returnstr"]],
      [:kernel_dispatch],

      [:pop],

      [:pusharg, [:get_inner_res]],
      [:pusharg, [:lit_str, "puts"]],
      [:kernel_dispatch],

      [:pop]
    ]
  end

  it "can unwind a :send to an object" do
    r = described_class.apply [
            [:send, :kernel, [[:lit_str, "lvar_get"], [:lit_str, "mystr"]]],
            [[:lit_str, "my message"]]
          ]
    r.should == [
      [:push],

      [:pusharg, [:lit_str, "my message"]],

      [:push],
      [:pusharg, [:lit_str, "mystr"]],
      [:pusharg, [:lit_str, "lvar_get"]],
      [:kernel_dispatch],
      [:pop],
      [:pusharg, [:get_inner_res]],
      
      [:object_dispatch],
      
      [:pop]
    ]
  end
end