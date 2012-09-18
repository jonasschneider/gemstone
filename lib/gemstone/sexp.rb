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
      type = primitive.shift

      if type == :call
        "printf(\"#{primitive.last}\\n\");"
      elsif type == :block
        primitive.map do |statement|
          self.compile(statement)
        end.join("\n")
      end
    end
  end
end