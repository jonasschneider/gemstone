module Gemstone
  module Kernel
    module Methods
      def self.puts
        [:pb_block,
          [:ps_cvar_assign, "arg", [:pi_poparg]],
          [:_raw, "LOG(\"fetched puts arg at %p\", arg);"],
          [:ps_print, [:pi_cvar_get, 'arg']]
        ]
      end

      def self.typeof
        [:pb_block,
          [:ps_cvar_assign, "arg", [:pi_poparg]],
          [:ps_set_typeof, [:pi_cvar_get, 'arg']]
        ]
      end

      def self.identity
        [:pb_block,
          [:ps_cvar_assign, "arg", [:pi_poparg]],
          [:ps_set_result, [:pi_cvar_get, 'arg']]
        ]
      end

      def self.lvar_assign
        [:pb_block,
          [:ps_cvar_assign, "name", [:pi_poparg]],
          [:ps_cvar_assign, "val", [:pi_poparg]],
          [:ps_lvar_assign, [:pi_cvar_get, 'name'], [:pi_cvar_get, 'val']]
        ]
      end

      def self.lvar_get
        [:pb_block,
          [:ps_cvar_assign, "arg", [:pi_poparg]],
          [:ps_set_result, [:pi_lvar_get, [:pi_cvar_get, 'arg']]],
          [:_raw, "LOG(\"fetched lvar at %p\", (*gs_stack_pointer).result);"]
        ]
      end

      def self.run_lambda
        [:pb_block,
          [:ps_cvar_assign, "arg", [:pi_poparg]],
          [:ps_call_lambda, [:pi_cvar_get, 'arg']]
        ]
      end

      def self.run_lambda_in_parent_frame
        [:pb_block,
          
          [:ps_cvar_assign, "arg", [:pi_poparg]],
          [:ps_pop],
          [:ps_call_lambda, [:pi_cvar_get, 'arg']],
          [:ps_push]
        ]
      end

      def self.set_message_dispatcher
        [:pb_block,
          [:ps_cvar_assign, "target", [:pi_poparg]],
          [:ps_cvar_assign, "dispatcher", [:pi_poparg]],
          [:ps_object_set_message_dispatcher, [:pi_cvar_get, 'target'], [:pi_cvar_get, 'dispatcher']]
        ]
      end
    end
  end
end