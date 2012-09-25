require 'treetop'
require 'polyglot'

require 'gemstone/parser/syntax'

module Gemstone
  module Parser
    def self.parse(code)
      parser = SyntaxParser.new
      result = parser.parse(code, root: 'program')
      unless result.nil?
        #raise result.inspect
        result.sexp
      else
        raise parser.failure_reason.inspect
      end
    end
  end
end