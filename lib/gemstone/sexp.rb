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
        "printf(#{self.compile(primitive.last)});printf(\"\\n\");\n"
      elsif type == :block
        primitive.map do |statement|
          self.compile(statement)
        end.join("\n")
      elsif type == :assign
        name = primitive.shift.to_s
        val = primitive.shift
        "char #{name}[#{val.length}] = {\"#{val}\"};\n"
      elsif type == :lvar
        "#{primitive.shift.to_s}"
      else
        raise "unknown sexp type #{type} - #{primitive.inspect}"
      end
    end
  end
end