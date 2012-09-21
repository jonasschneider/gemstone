module Gemstone
  module Transformations
    class UnwindStack
      def self.apply(node)
        node = node.dup
        target = node.shift
        steps = []
        message_parts = node.shift.reverse

        steps << [:ps_push]
        
        part_refs = message_parts.map do |part|
          steps.concat traverse(part)
        end

        if target == :kernel
          steps << [:ps_kernel_dispatch]
        else
          steps.concat traverse(target)
          steps << [:ps_init_lscope]  # create a new local scope for non-kernel calls
          steps << [:ps_object_dispatch]
        end

        steps << [:ps_pop]
        
        steps
      end


      def self.traverse(part)
        steps = []
        if part.first == :send
          # Nested call
          part.shift

          steps.concat self.apply(part)

          steps << [:ps_pusharg, [:pi_get_inner_res]]
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