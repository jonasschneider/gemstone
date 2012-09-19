module Gemstone
  def self.compile(list_sexp, binary_path)

    compiler = Compiler.new
    main = compiler.compile_sexp(list_sexp)

    c = compiler.literals.join("\n") + main

    #code = 
    wrapped = <<C
#include <stdio.h>
#include "gemstone.h"

int main() {

gs_stack_init();

#{c} 

return 0;

}
C
    code = File.new('tmp/code.c', 'w')
    code.write(wrapped)
    code.close

    l = 0
    formatted = wrapped.gsub(/^/) do
      l += 1
      l.to_s.ljust(4)
    end
    puts "# CODE:\n\n#{formatted}"

    out = %x(gcc -Wall -g -Ilib/gemstone tmp/code.c -o #{binary_path} 2>&1)
    if $? != 0
      msg = "### COMPILE ERROR\n# GCC OUT:\n\n #{out}"
      raise msg
    end
  end

  class Compiler
    attr_reader :literals
    def initialize
      @literals = []
      @decls = {}
      @level = 0
    end

    def log(msg, additional_indent = 0)
      indent = '  '*@level
      puts "#{indent} #{msg.gsub("\n", "\n "+indent+' '*additional_indent)}"
    end


    def compile_sexp(primitive)
      log primitive.inspect
      @level += 1
      if String === primitive
        raise "bare string #{primitive.inspect}"
      end

      if Fixnum === primitive
        return primitive.to_s
      end

      primitive = primitive.dup

      type = primitive.shift

      val = if type == :call
        func = primitive.shift
        if func == :println
          arg = primitive.shift
          self.compile_sexp([:if, 
              [:primitive_equal, [:call, :typeof_internal, arg], [:c_const, "GS_TYPE_STRING"]], 
              [:call, :printf, arg],
              [:call, :printf, [:lit_str, "Runtime error, expected string"]] 
          ])
        elsif func == :printf
          "printf(\"%s\", (#{self.compile_sexp(primitive.shift)}).string);printf(\"\\n\");\n"
        elsif func == :typeof_internal
          arg = self.compile_sexp(primitive.shift)
          "gemstone_typeof(&#{arg})"
        elsif func == :typeof
          arg = primitive.shift
          #{}"(gemstone_typeof(#{arg}) == GS_TYPE_STRING ? \"string\" : " + 
           # "(gemstone_typeof(#{arg}) == GS_TYPE_FIXNUM ? \"fixnum\" : \"\")" +  ")"
          self.compile_sexp([:if, 
              [:primitive_equal, [:call, :typeof_internal, arg], [:c_const, "GS_TYPE_STRING"]], 
              [:setres, [:lit_str, "string"]],
              [:setres, [:lit_str, "fixnum"]]
          ])
        else
          raise "unknown call: #{func} - #{primitive.inspect}"
        end
      elsif type == :block
        primitive.map do |statement|
          self.compile_sexp(statement)
        end.join("\n")
      elsif type == :assign
        name = primitive.shift.to_s
        val = self.compile_sexp(primitive.shift)
        if @decls[name]
          decl = ''
        else
          @decls[name] = true
          decl = "struct gs_value #{name};\n"
        end
        "#{decl}#{name} = #{val};\n"
      elsif type == :assign_cvar
        name = primitive.shift.to_s
        val = primitive.shift

        if @decls[name]
          decl = ''
        else
          @decls[name] = true
          decl = "struct gs_value #{name};\n"
        end
        if String === val
          "#{decl}gs_str_new(&#{name}, \"#{val}\", #{val.bytesize});\n"
        else
          "#{decl}gs_fixnum_new(&#{name}, #{val});\n"
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
        primitive.shift.to_s
      elsif type == :lit_str
        str = primitive.shift
        raise 'need string' unless String === str
        name = 'lit_str_'+@literals.length.to_s+'_'+str.gsub(/[^a-zA-Z]/, '_')
        @literals << self.compile_sexp([:assign_cvar, name, str])
        name
      elsif type == :lit_fixnum
        fixnum = primitive.shift
        raise 'need fixnum' unless Fixnum === fixnum
        name = 'lit_fixnum_'+@literals.length.to_s+'_'+fixnum.to_s
        @literals << self.compile_sexp([:assign_cvar, name, fixnum])
        name
      elsif type == :c_const
        primitive.shift



      elsif type == :send
        def traverse(node)
          node = node.dup
          target = node.shift
          steps = [:block]
          raise 'can only send to kernel' if target != :kernel
          message_parts = node.shift.reverse

          steps << [:push, message_parts.inspect]

          part_refs = message_parts.map do |part|
            if part.first == :send
              part.shift
              @level += 1
              r = traverse(part)

              @level -= 1
            else
              log "compiling: #{part}"
              r = self.compile_sexp(part)
              
            end

            steps << r
            steps << [:pusharg, [:get_inner_res]]
          end

          steps << [:kernel_dispatch]
          
          steps
        end
        res = traverse(primitive)


        self.compile_sexp(res)

      elsif type == :strings_equal
        a = primitive.shift
        b = primitive.shift
        "strcmp((#{self.compile_sexp(a)}).string, (#{self.compile_sexp(b)}).string)==0"
      elsif type == :nopstr
        str = primitive.shift
        { setup: [:nop], reference: str }
      
      elsif type == :push
        "gs_stack_push();                           // >>>>>>>>>>>> #{primitive.shift}"
      elsif type == :pop
        "gs_stack_pop();                         // <<<<<<<<<<<<"

      elsif type == :poparg
        "*gs_argstack_pop();                  // <<<"
      elsif type == :pusharg
        what = self.compile_sexp(primitive.shift)
        "gs_argstack_push(&#{what});                  // >>>"
      elsif type == :setres
        "(*gs_stack_pointer).result = &#{self.compile_sexp(primitive.shift)};                         // ============"
      elsif type == :get_inner_res
        "*(gs_stack_pointer+1)->result"
      elsif type == :nop

      elsif type == :kernel_dispatch
        sexp = 
        [:block, 
          [:assign, :called_func, [:poparg]],
          [:assign, :arg, [:poparg]],
          
          [:if, 
            [:strings_equal, [:lvar, :called_func], [:lit_str, "puts"]],
            [:call, :println, [:lvar, :arg]],
            [:if, 
              [:strings_equal, [:lvar, :called_func], [:lit_str, "typeof"]],
              [:call, :typeof, [:lvar, :arg]],
              [:if, 
                [:strings_equal, [:lvar, :called_func], [:lit_str, "returnstr"]],
                [:setres, [:lvar, :arg]],
                [:nop]
              ]
            ]
          ],
          [:setres, [:lit_str, "my return value"]]
        ]

        self.compile_sexp(sexp)

      elsif type == :dyn_str
        str = primitive.shift
        name = 'dyn_str_'+str.gsub(/[^a-zA-Z]/, '_')[0,30]

        [:block, [:assign_cvar, name, str], [:pusharg, [:lvar, name]]]
      elsif type == :dyn_fixnum
        num = primitive.shift
        name = 'dyn_fixnum_'+num.to_s

        [:block, [:assign_cvar, name, num], [:pusharg, [:lvar, name]]]
      else
        raise "unknown sexp type #{type} - #{primitive.inspect}"
      end
      @level -= 1
      log "=> #{val}", 3
      val
    end
  end
end