require 'gemstone/kernel/methods'

module Gemstone
  module Kernel
    def self.dispatcher_sexp
      tree = recurse(Gemstone::Kernel::Methods.singleton_methods)

      sexp = 
      [:pb_block, 
        [:ps_cvar_assign, 'called_func', [:pi_poparg]],
        
        [:_raw, 'LOG("running kernel call \'%s\'", called_func->string);'+"\n"],

        tree,
        
        [:pb_if,
          [:pi_c_equal, [:pi_get_result], 0],
          [:ps_set_result, [:pi_lit_str, "last kernel call did not provide a return value"]],
          [:nop]
        ],

        [:_raw, 'INFO("kernel dispatch complete");'+"\n"]
      ]
    end


    def self.recurse(methods)
      meth = methods.shift
      invocation = Gemstone::Kernel::Methods.send(meth)

      if methods.empty?
        tail = [:pb_block,
          [:ps_print, [:pi_lit_str, "unknown kernel message:"]],
          [:ps_print, [:pi_cvar_get, 'called_func']]
        ]
      else
        tail = recurse(methods)
      end

      [:pb_if, 
        [:pi_stringvals_equal, [:pi_cvar_get, 'called_func'], [:pi_lit_str, meth.to_s]],
        invocation,
        tail
      ]
    end
  end
end