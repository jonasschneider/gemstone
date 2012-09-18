require 'gemstone/sexp'

module Gemstone
  def self.compile(list_sexp, binary_path)

    c = Sexp::compile(list_sexp)

    #code = 
    wrapped = "#include <stdio.h>\nint main() { #{c} }"
    code = File.new('tmp/code.c', 'w')
    code.write(wrapped)
    code.close

    out = %x(gcc tmp/code.c -o #{binary_path} 2>&1)
    if $? != 0
      msg = "### COMPILE ERROR\n# CODE:\n\n#{wrapped}\n\n # GCC OUT:\n\n #{out}"
      raise msg
    end
  end
end