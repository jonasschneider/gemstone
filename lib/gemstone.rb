require 'gemstone/sexp'

module Gemstone
  def self.compile(list_sexp, binary_path)

    c = self.compile_sexp(list_sexp)

    #code = 
    wrapped = "#include <stdio.h>\n#include \"gemstone.h\"\n\nint main() { #{c} }"
    code = File.new('tmp/code.c', 'w')
    code.write(wrapped)
    code.close

    out = %x(gcc -Ilib/gemstone tmp/code.c -o #{binary_path} 2>&1)
    if $? != 0
      msg = "### COMPILE ERROR\n# CODE:\n\n#{wrapped}\n\n # GCC OUT:\n\n #{out}"
      raise msg
    end
  end


  def self.compile_sexp(primitive)
    if String === primitive
      return "\"#{primitive}\""
    end

    if Fixnum === primitive
      return primitive.to_s
    end

    type = primitive.shift

    if type == :call
      func = primitive.shift
      if func == :puts
        "printf(#{self.compile_sexp(primitive.shift)});printf(\"\\n\");\n"
      elsif func == :typeof
        arg = self.compile_sexp(primitive.shift)
        "(gemstone_typeof(#{arg}) == GS_TYPE_STRING ? \"string\" : " + 
          "(gemstone_typeof(#{arg}) == GS_TYPE_FIXNUM ? \"fixnum\" : \"\")" +  ")"
      else
        raise "unknown call: #{func} - #{primitive.inspect}"
      end
    elsif type == :block
      primitive.map do |statement|
        self.compile_sexp(statement)
      end.join("\n")
    elsif type == :assign
      name = primitive.shift.to_s
      val = primitive.shift
      if String === val
        "struct gs_value lvar_#{name};\ngs_str_new(&lvar_#{name}, \"#{val}\", #{val.bytesize});\n"
      else
        "struct gs_value lvar_#{name};\ngs_fixnum_new(&lvar_#{name}, #{val});\n"
      end
    elsif type == :if
      cond = self.compile_sexp(primitive.shift)
      then_code = self.compile_sexp(primitive.shift)
      else_code = self.compile_sexp(primitive.shift)
      "if(#{cond}) {\n#{then_code}\n} else { \n#{else_code}\n}\n"
    elsif type == :primitive_equal
      left = self.compile_sexp(primitive.shift)
      right = self.compile_sexp(primitive.shift)
      "#{left} == #{right}"
    elsif type == :lvar
      "&lvar_#{primitive.shift.to_s}"
    else
      raise "unknown sexp type #{type} - #{primitive.inspect}"
    end
  end
end