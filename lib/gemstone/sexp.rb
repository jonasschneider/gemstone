module Gemstone
  module Sexp
    class Code
      def initialize(code)
        @code = code
      end

      def self.compile
        @code
      end
    end

    def self.compile(primitive)
      if String === primitive
        return "\"#{primitive}\""
      end

      type = primitive.shift

      if type == :call
        func = primitive.shift
        if func == :puts
          "printf(#{self.compile(primitive.shift)});printf(\"\\n\");\n"
        elsif func == :typeof
          arg = self.compile(primitive.shift)
          "(#{arg}->type == GEMSTONE_TYPE_STRING ? \"string\" : "")"
        else
          raise "unknown call: #{func} - #{primitive.inspect}"
        end
      elsif type == :block
        primitive.map do |statement|
          self.compile(statement)
        end.join("\n")
      elsif type == :assign
        name = primitive.shift.to_s
        val = primitive.shift
        if String === val
          "char #{name}[#{val.length}] = {\"#{val}\"};\n"
        else
          "unsigned long #{name} = #{val};\n"
        end
      elsif type == :lvar
        "#{primitive.shift.to_s}"
      else
        raise "unknown sexp type #{type} - #{primitive.inspect}"
      end
    end
  end
end