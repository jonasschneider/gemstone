require 'gemstone/kernel'
require 'gemstone/transformations/unwind_stack'

module Gemstone
  def self.compile(list_sexp, binary_path)

    compiler = Compiler.new
    main = compiler.compile_sexp(list_sexp)

    c = main

    #code = 
    wrapped = <<C
#include <stdio.h>
#include "gemstone.h"

void kernel_dispatch() {
  #{compiler.compile_sexp(Kernel.dispatcher_sexp)}
}

#{compiler.lambdas.join("\n")}

int main() {

gs_stack_init();
gs_stack_push_with_lscope(); // so we have a local scope


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

    out = %x(gcc -Wall -g -DDEBUG -Iinclude tmp/code.c -o #{binary_path} 2>&1)
    if $? != 0
      msg = "### COMPILE ERROR\n# GCC OUT:\n\n #{out}"
      raise msg
    end
  end

  class Compiler
    attr_reader :lambdas
    def initialize
      @lambdas = []
      @decls = {}
      @level = 0
      @uuid = 0
    end

    def uuid
      @uuid += 1
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
              [:call, :print_string, arg],
              [:if, 
                [:primitive_equal, [:call, :typeof_internal, arg], [:c_const, "GS_TYPE_FIXNUM"]], 
                [:call, :print_fixnum, arg],
                [:call, :print_string, [:lit_str, "Runtime error, expected string or fixnum"]]
              ]
          ])
        elsif func == :print_fixnum
          "printf(\"%lld\\n\", #{self.compile_sexp([:getnum, primitive.shift])});\n"
        elsif func == :print_string
          "printf(\"%s\", #{self.compile_sexp([:getstring, primitive.shift])});printf(\"\\n\");\n"
        elsif func == :typeof_internal
          arg = self.compile_sexp(primitive.shift)
          "gemstone_typeof(#{arg})"
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
          decl = "struct gs_value *#{name};\n"
        end
        "#{decl}#{name} = #{val};\n"
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
        "gs_string_literal(\"#{str}\", #{str.bytesize})"
      elsif type == :lit_fixnum
        fixnum = primitive.shift
        raise 'need fixnum' unless Fixnum === fixnum
        "gs_fixnum_literal(#{fixnum})"
      elsif type == :c_const
        primitive.shift


      elsif type == :lvar_assign
        n, v = self.compile_sexp([:getstring, primitive.shift]), self.compile_sexp(primitive.shift)
        "gs_lvars_assign(#{n}, #{v});"

      elsif type == :lvar_get
        n = self.compile_sexp([:getstring, primitive.shift])
        "gs_lvars_fetch(#{n})"

      elsif type == :getstring
        "(#{self.compile_sexp(primitive.shift)})->string"

      elsif type == :getnum
        "(#{self.compile_sexp(primitive.shift)})->fixnum"
      
      elsif type == :send
        res = [:block].concat Gemstone::Transformations::UnwindStack.apply(primitive)
        self.compile_sexp(res)

      elsif type == :strings_equal
        a = self.compile_sexp([:getstring, primitive.shift])
        b = self.compile_sexp([:getstring, primitive.shift])
        "strcmp(#{a}, #{b})==0"
      
      elsif type == :lambda
        name = "my_lambda_#{@lambdas.length}"
        funcname = name + '_func'
        valname = name + '_val'
        procedure = self.compile_sexp(primitive.shift)
        func = <<C

void #{funcname}(void) {
  INFO("inside lambda");

  #{procedure}

  INFO("lambda done");
}
C
        x =<<C
struct gs_value *#{valname} = malloc(sizeof(struct gs_value));
memset(#{valname}, 0, sizeof(struct gs_value));
#{valname}->type = GS_TYPE_LAMBDA;

#{valname}->lambda_func = &#{funcname};

gs_argstack_push(#{valname});
C
        @lambdas << func
        x      
      elsif type == :call_lambda
        "arg->lambda_func();"
      elsif type == :push
        "gs_stack_push();                           // >>>>>>>>>>>> #{primitive.shift}"
      elsif type == :pop
        "gs_stack_pop();                         // <<<<<<<<<<<<"

      elsif type == :init_lscope
        "gs_lvars_init();                           // LSCOPE"


      elsif type == :poparg
        "gs_argstack_pop()"
      elsif type == :pusharg
        what = self.compile_sexp(primitive.shift)
        "gs_argstack_push(#{what});"
      elsif type == :setres
        "(*gs_stack_pointer).result = #{self.compile_sexp(primitive.shift)};                         // ============"
      elsif type == :getres
        "(*gs_stack_pointer).result"
      elsif type == :get_inner_res
        "(gs_stack_pointer+1)->result"
      elsif type == :nop

      elsif type == :kernel_dispatch
        "kernel_dispatch();"

      elsif type == :raw
        primitive.shift

      elsif type == :object_set_message_dispatcher
        name = 'object_set_message_dispatcher_'+uuid.to_s
        x=<<C
/* SET DISPATCHER */
struct gs_value *#{name} = #{self.compile_sexp(primitive.shift)};
#{name}->dispatcher = #{self.compile_sexp(primitive.shift)};
C
      elsif type == :object_dispatch
        name = 'dispatch_'+uuid.to_s
        x=<<C
struct gs_value *#{name} = #{self.compile_sexp([:poparg])};
if(#{name}->dispatcher) {
  #{self.compile_sexp([:send, :kernel, [[:lit_str, "run_lambda"], [:raw, "#{name}->dispatcher"]]])}
} else {
  #{self.compile_sexp([:send, :kernel, [[:lit_str, "puts"], [:lit_str, "message sent to value without dispatcher"]]])}
}

C

      else
        raise "unknown sexp type #{type} - #{primitive.inspect}"
      end
      @level -= 1
      #log "=> #{val}", 3
      val
    end
  end
end