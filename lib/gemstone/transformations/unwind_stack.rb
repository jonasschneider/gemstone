module Gemstone
  module Transformations
    class UnwindStack
      def self.apply(node)
        node = node.dup
        target = node.shift
        steps = []
        message_parts = node.shift.reverse

        steps << [:push]

        part_refs = message_parts.map do |part|
          steps.concat traverse(part)
        end

        if target == :kernel
          steps << [:kernel_dispatch]
        else
          steps.concat traverse(target)
          steps << [:object_dispatch]
        end

        steps << [:pop]
        
        steps
      end


      def self.traverse(part)
        steps = []
        if part.first == :send
          # Nested call
          part.shift

          steps.concat self.apply(part)

          steps << [:pusharg, [:get_inner_res]]
        elsif part.first == :lambda
          steps << part
        else
          # Static call
          steps << [:pusharg, part]
        end
        steps
      end
    end
  end
end