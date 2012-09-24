require 'env'

describe Gemstone do
  it "can send messages to kernel" do
    out = compile_and_execute [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "Hello world"]]]
    out.should eq("Hello world\n")
  end

  it "can send nested messages to kernel" do
    out = compile_and_execute [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "identity"], [:pi_lit_str, "Stackstring"]]]]]
    out.should eq("Stackstring\n")
  end

  it "shows the type of a string" do
    out = compile_and_execute [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "typeof"], [:pi_lit_str, "Stackstring"]]]]]
    out.should eq("string\n")
  end

  it "shows the type of a number" do
    out = compile_and_execute [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "typeof"], [:pi_lit_fixnum, 1337]]]]]
    out.should eq("fixnum\n")
  end

  it "runs puts from stack" do
    out = compile_and_execute [:pb_block,
      [:ps_push],
      [:ps_pusharg, [:pi_lit_str, "Stackstring"]],
      [:ps_pusharg, [:pi_lit_str, "puts"]],
      [:ps_kernel_dispatch],
      [:ps_pop]
    ]
    out.should eq("Stackstring\n")
  end

  it "can puts a fixnum" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mynum"], [:pi_lit_fixnum, 1337]]],
        [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mynum"]]]]]
      ]

    out.should eq("1337\n")
  end

  it "runs puts from stack with argument from deeper within" do
    out = compile_and_execute [:pb_block,
      [:ps_push],
      [:ps_push],

      [:ps_pusharg, [:pi_lit_str, "Stackstring"]],
      [:ps_pusharg, [:pi_lit_str, "identity"]],
      [:ps_kernel_dispatch],

      [:ps_pop],

      [:ps_pusharg, [:pi_get_inner_res]],
      [:ps_pusharg, [:pi_lit_str, "puts"]],
      [:ps_kernel_dispatch],

      [:ps_pop]
    ]
    out.should eq("Stackstring\n")
  end

  it "has local variables" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "ohai"]]],
        [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]]]]]
    out.should eq("ohai\n")
  end

  it "can reassign local variables" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "checker"], [:pi_lit_str, "first value"]]],
        [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "checker"]]]]],

        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "checker"], [:pi_lit_str, "second value"]]],
        [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "checker"]]]]]
      ]
    out.should eq("first value\nsecond value\n")
  end

  it "sets a default message when the dispatched action does not set a return value" do
    out = compile_and_execute [:pb_block,
      [:ps_push],
      [:ps_push],

      [:ps_pusharg, [:pi_lit_str, "some string"]],
      [:ps_pusharg, [:pi_lit_str, "puts"]],
      [:ps_kernel_dispatch],

      [:ps_pop],

      [:ps_pusharg, [:pi_get_inner_res]],
      [:ps_pusharg, [:pi_lit_str, "puts"]],
      [:ps_kernel_dispatch]
    ]
    out.should eq("some string\nlast kernel call did not provide a return value\n")
  end


  it "has a lambda" do
    lambda = 
      [:ps_push_lambda,
        [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "hello from the lambda"]]]
      ]
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "run_lambda"], lambda, [:pi_lit_fixnum, 0]]]
      ]
    out.should eq("hello from the lambda\n")

    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mylambda"], [:ps_push_lambda,
          [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "hello from the lambda"]]]
        ]]],
        [:send, :kernel, [[:pi_lit_str, "run_lambda"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mylambda"]]], [:pi_lit_fixnum, 0]]],
        [:send, :kernel, [[:pi_lit_str, "run_lambda"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mylambda"]]], [:pi_lit_fixnum, 0]]]
      ]
    out.should eq("hello from the lambda\n"*2)
  end

  it "can have multiple lambdas" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "lambda1"], [:ps_push_lambda,
          [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "hello from the first lambda"]]]
        ]]],
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "lambda2"], [:ps_push_lambda,
          [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "hello from the second lambda"]]]
        ]]],
        [:send, :kernel, [[:pi_lit_str, "run_lambda"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "lambda2"]]], [:pi_lit_fixnum, 0]]],
        [:send, :kernel, [[:pi_lit_str, "run_lambda"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "lambda1"]]], [:pi_lit_fixnum, 0]]]
      ]
    out.should eq("hello from the second lambda\nhello from the first lambda\n")
  end
end