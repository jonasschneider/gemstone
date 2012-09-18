module Gemstone
  def self.compile(sexp)
    c = "#include <stdio.h>\nint main() { printf(\"Hello world\"); }"
    code = File.new('tmp/code.c', 'w')
    code.write(c)
    code.close

    out = 'tmp/a.out'
    puts %x(gcc tmp/code.c -o #{out})
    out
  end
end