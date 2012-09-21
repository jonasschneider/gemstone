require 'gemstone/kernel/methods'

module Gemstone
  module Kernel
    def self.dispatcher_sexp
      tree = recurse(Gemstone::Kernel::Methods.singleton_methods)

      sexp = 
      [:block, 
        [:assign, :called_func, [:poparg]],
        [:assign, :arg, [:poparg]],

        [:raw, 'LOG("running kernel call \'%s\'", called_func->string);'+"\n"],

        tree,
        
        [:if,
          [:primitive_equal, [:getres], 0],
          [:setres, [:lit_str, "last kernel call did not provide a return value"]],
          [:nop]
        ],

        [:raw, 'INFO("kernel dispatch complete");'+"\n"]
      ]
    end


    def self.recurse(methods)
      meth = methods.shift
      invocation = Gemstone::Kernel::Methods.send(meth, [:lvar, :arg])

      if methods.empty?
        tail = [:block,
          [:call, :println, [:lit_str, "unknown kernel message:"]],
          [:call, :println, [:lvar, :called_func]]
        ]
      else
        tail = recurse(methods)
      end

      [:if, 
        [:strings_equal, [:lvar, :called_func], [:lit_str, meth.to_s]],
        invocation,
        tail
      ]
    end
  end
end