require 'gemstone'

describe Gemstone do
  let(:path_to_binary) { 'tmp/a.out' }
  
  before do
    File.unlink path_to_binary if File.exists? path_to_binary
  end

  def compile_and_execute(sexp)
    Gemstone.compile sexp, path_to_binary
    o = %x(#{path_to_binary})
    p o
    $?.exitstatus.should eq(0)
    o
  end

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

  context "sending messages to values" do
    it "throws an error if no dispatcher is set" do
      pending
      out = compile_and_execute [:pb_block, 
          [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "ohai"]]],

          [:send, 
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [[:pi_lit_str, "my message"]]
          ]
        ]
      out.should eq("message sent to value without dispatcher\n")
    end

    it "a message dispatcher for a string can be set and gets called with arguments" do
      out = compile_and_execute [:pb_block, 
          [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "ohai"]]],

          [:send, :kernel, [[:pi_lit_str, "set_message_dispatcher"],
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [:ps_push_lambda, [:pb_block,
              [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "hello from the string message dispatcher"]]],
              [:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "your message was:"]]],
              [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "getarg"], [:pi_lit_fixnum, 1]]]]]
            ]]
          ]],

          [:_raw, 'INFO("dispatcher set, sending message to mystr");'],

          [:send, 
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [[:pi_lit_str, "my message"]]
          ]
        ]
      out.should eq("hello from the string message dispatcher\nyour message was:\nmy message\n")
    end

    it "creates a new local scope for the dispatcher" do
      out = compile_and_execute [:pb_block, 
          [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "checker"], [:pi_lit_str, "outer val"]]],
          [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "checker"]]]]],
          [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "ohai"]]],

          [:send, :kernel, [[:pi_lit_str, "set_message_dispatcher"],
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [:ps_push_lambda, [:pb_block,
              [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "checker"], [:pi_lit_str, "inner val"]]],
              [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "checker"]]]]]
            ]]
          ]],

          [:send, 
            [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
            [[:pi_lit_str, "my message"]]
          ],

          [:send, :kernel, [[:pi_lit_str, "puts"], [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "checker"]]]]]
        ]
      out.should eq("outer val\ninner val\nouter val\n")
    end

    it "can query a string for its length" do
      out = compile_and_execute [:pb_block, 
          [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "0123456789"]]],
          [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "longer"], [:pi_lit_str, "01234567890123456789"]]],

          [:send, :kernel,
            [[:pi_lit_str, "puts"],
            [:send, 
              [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
              [[:pi_lit_str, "length"]]
            ]
          ]],

          [:send, :kernel,
            [[:pi_lit_str, "puts"],
            [:send, 
              [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "longer"]]],
              [[:pi_lit_str, "length"]]
            ]
          ]]
        ]
      out.should eq("10\n20\n")
    end

    it "can add two fixnums" do
      out = compile_and_execute [:pb_block, 
          [:ps_cast, [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "a"], [:pi_lit_fixnum, 3]]]],
          [:ps_cast, [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "b"], [:pi_lit_fixnum, 2]]]],
          
          [:ps_cast, [:send, :kernel,
            [[:pi_lit_str, "puts"],
            [:send, 
              [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "a"]]],
              [
                [:pi_lit_str, "+"],
                [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "b"]]]
              ]
            ]
          ]]],
        ]
      out.should eq("5\n")
    end
  end
end