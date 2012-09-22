module Gemstone
  module Transformations
    class UnwindStack
      def self.apply(node)
        node = node.dup
        target = node.shift
        steps = []
        message_parts = node.shift.reverse

        
        
        part_refs = message_parts.map do |part|
          steps.concat traverse(part)
        end

        if target == :kernel
          steps << [:ps_kernel_dispatch]
        else
          steps.concat traverse(target)
          steps << [:ps_push_with_argstack_as_params]
          steps << [:ps_object_dispatch]
          steps << [:ps_pop]
        end

        
        
        steps
      end


      def self.traverse(part)
        steps = []
        if part.first == :send
          # Nested call
          part.shift

          steps.concat self.apply(part)

          steps << [:ps_pusharg, [:pi_get_result]]
        elsif part.first.to_s.start_with?('ps_push_')
          steps << part
        else
          # Static call
          steps << [:ps_pusharg, part]
        end
        steps
      end
    end
  end
end