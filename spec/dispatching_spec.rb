require 'env'

describe Gemstone, "dispatching messages to values" do
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

  it "breaks when trying to access a non-existing local variable"

  it "can define a method on an object" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "my test string"]]],
        
        [:send,
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
          [
            [:pi_lit_str, "define_method"],
            [:pi_lit_str, "my_method_name"],
            [:ps_push_lambda, [:pb_block,
              [:ps_hello_world]
            ]]
          ]
        ],

        [:send, 
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
          [[:pi_lit_str, "my_method_name"]]
        ]
      ]
    out.should eq("Hello world!\n")
  end

  it "can define a method on an object that takes a parameter" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "my test string"]]],
        
        [:send,
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
          [
            [:pi_lit_str, "define_method"],
            [:pi_lit_str, "my_method_name"],
            [:ps_push_lambda, [:pb_block,
              [:ps_print, [:pi_lit_str, "Hello from dat method. Your param:"]],
              [:send, :kernel,
                [
                  [:pi_lit_str, "puts"],
                  [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]]
                ]
              ]
            ], [:pi_lit_str, "mystr"]]
          ]
        ],

        [:send, 
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
          [
            [:pi_lit_str, "my_method_name"],
            [:pi_lit_str, "some cool string"],
          ]
        ]
      ]
    out.should eq("Hello from dat method. Your param:\nsome cool string\n")
  end

  it "can define and call a method on an object that takes two parameters" do
    out = compile_and_execute [:pb_block, 
        [:send, :kernel, [[:pi_lit_str, "lvar_assign"], [:pi_lit_str, "mystr"], [:pi_lit_str, "my test string"]]],
        
        [:send,
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
          [
            [:pi_lit_str, "define_method"],
            [:pi_lit_str, "my_method_name"],
            [:ps_push_lambda, [:pb_block,
              [:send, :kernel,
                [
                  [:pi_lit_str, "puts"],
                  [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]]
                ]
              ],
              [:send, :kernel,
                [
                  [:pi_lit_str, "puts"],
                  [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "lol"]]]
                ]
              ]
            ], [:pi_lit_str, "mystr"], [:pi_lit_str, "lol"]]
          ]
        ],

        [:send, 
          [:send, :kernel, [[:pi_lit_str, "lvar_get"], [:pi_lit_str, "mystr"]]],
          [
            [:pi_lit_str, "my_method_name"],
            [:pi_lit_str, "some cool string"],
            [:pi_lit_str, "another string"],
          ]
        ]
      ]
    out.should eq("some cool string\nanother string\n")
  end

  it "can query a string for its length" do
    pending
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
    pending
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