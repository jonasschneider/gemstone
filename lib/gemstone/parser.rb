require 'treetop'
require 'polyglot'

require 'gemstone/parser/syntax'

module Gemstone
  module Parser
    def self.parse(code)
      parser = SyntaxParser.new
      result = parser.parse(code, root: 'program')
      if result
        #p result
        result.sexp
      else
        raise parser.failure_reason.inspect
      end
    end
  end
end