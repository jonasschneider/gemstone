require 'gemstone/kernel'
require 'gemstone/transformations/unwind_stack'

module Gemstone
  def self.compile(list_sexp, binary_path)

    compiler = Compiler.new
    main = compiler.compile_sexp(list_sexp)

    c = main

    wrapped = <<C
#include <stdio.h>
#include "gemstone.h"

void kernel_dispatch() {
  #{compiler.compile_sexp(Kernel.dispatcher_sexp)}
}

void string_dispatch() {

  #{compiler.compile_sexp [:ps_set_result, [:pi_lit_fixnum, [:_raw, 'strlen(gs_stack_pointer->receiver->string)']]]}
}

void fixnum_dispatch() {
  #{compiler.compile_sexp [:ps_set_result, [:pi_lit_fixnum, [:_raw, '(gs_stack_pointer->receiver->fixnum + gs_stack_pointer->parameters[2]->fixnum)']]]}
}


#{compiler.lambdas.join("\n")}

int main() {

gs_stack_init();
gs_stack_push(); // so we have a local scope


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

      ### There are three types of primitives:
      # 1. Primitive setters - They are C statements and do something, not modifying the argstack.
      # 2. Primitive getters - They are C statements and push something on the argstack.
      # 3. Primitive blocks - They are C statements, do not modify the argstack and can contain non-primitive nodes. 
      # 3. Primitive inlines - They are C expressions which evaluate to gs_value struct pointers, potentially modifying the argstack.
      #
      # Primitive getters and setters together form the group of primitive statements.
      # 
      # The primitive setters and getters are named by the effect they have on the environment - primitives that
      # query the environment and provide information flow into the program are getters, primitives that change
      # the environment and provide information flow out of the program are setters.
      # 
      # Primitive node types are prefixed with `p{s,g,i}_` respectively.
      #
      # Within the syntax tree, non-primitive nodes can only be nested under other non-primitive nodes and primitive blocks.
      # Primitive nodes, however, can generally be nested under any node.
      # This means i.e. that you cannot use the result of :send, a non-primitive, as the argument to a primitive.
      #
      # An even stricter rule is that all descendants of primitive statements must be primitive inlines;
      # This rule stems naturally from the fact that primitive statements may not be nested and may not contain
      # non-primitive nodes.

      # In the course of compiling, the syntax tree is transformed in order to replace all non-primitive nodes 
      # by a series of equivalent primitives.
      # The resulting pure tree of primitives is then transformed into the output C code.


      val = 
      #
      # PRIMITIVE STATEMENTS
      #
      if type == :ps_print
        arg = primitive.shift
        self.compile_sexp([:pb_if, 
            [:pi_c_equal, [:pi_typeof, arg], [:pi_c_const, "GS_TYPE_STRING"]], 
            [:ps_print_string, arg],
            [:pb_if, 
              [:pi_c_equal, [:pi_typeof, arg], [:pi_c_const, "GS_TYPE_FIXNUM"]], 
              [:ps_print_fixnum, arg],
              [:ps_print_string, [:pi_lit_str, "Runtime error, expected string or fixnum"]]
            ]
        ])
      
      elsif type == :ps_print_fixnum
        "printf(\"%lld\\n\", #{self.compile_sexp([:pi_get_fixnum, primitive.shift])});\n"
      
      elsif type == :ps_print_string
        "printf(\"%s\", #{self.compile_sexp([:pi_get_str, primitive.shift])});printf(\"\\n\");\n"
      
      elsif type == :ps_cvar_assign
        name = primitive.shift.to_s
        val = self.compile_sexp(primitive.shift)
        decl = "struct gs_value *#{name};\n"
        "#{decl}#{name} = #{val};\n"
      
      elsif type == :ps_push
        "gs_stack_push();                           // >>>>>>>>>>>> #{primitive.shift}"
      
      elsif type == :ps_pop
        "gs_stack_pop();                         // <<<<<<<<<<<<"

      elsif type == :ps_init_lscope
        "gs_lvars_init();                           // LSCOPE"

      elsif type == :ps_set_result
        "(*gs_stack_pointer).result = #{self.compile_sexp(primitive.shift)};"

      elsif type == :ps_set_typeof
        arg = primitive.shift
        #{}"(gemstone_typeof(#{arg}) == GS_TYPE_STRING ? \"string\" : " + 
         # "(gemstone_typeof(#{arg}) == GS_TYPE_FIXNUM ? \"fixnum\" : \"\")" +  ")"
        self.compile_sexp([:pb_if, 
            [:pi_c_equal, [:pi_typeof, arg], [:pi_c_const, "GS_TYPE_STRING"]], 
            [:ps_set_result, [:pi_lit_str, "string"]],
            [:ps_set_result, [:pi_lit_str, "fixnum"]]
        ])

      elsif type == :ps_lvar_assign
        n, v = self.compile_sexp([:pi_get_str, primitive.shift]), self.compile_sexp(primitive.shift)
        "gs_lvars_assign(#{n}, #{v});"
     
      elsif type == :ps_push_lambda
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

      elsif type == :ps_call_lambda
        "#{self.compile_sexp(primitive.shift)}->lambda_func();"

      elsif type == :ps_object_set_message_dispatcher
        name = 'object_set_message_dispatcher_'+uuid.to_s
        x=<<C
/* SET DISPATCHER */
struct gs_value *#{name} = #{self.compile_sexp(primitive.shift)};
#{name}->dispatcher = #{self.compile_sexp(primitive.shift)};
C
      elsif type == :ps_object_dispatch
        name = 'dispatch_'+uuid.to_s
        x=<<C
  INFO("calling dat dispatcher");
struct gs_value *#{name} = (*gs_stack_pointer).parameters[0];
gs_stack_pointer->receiver = #{name};

if(#{name}->dispatcher) {

  #{self.compile_sexp([:send, :kernel, [[:pi_lit_str, "run_lambda"], [:_raw, "#{name}->dispatcher"]]])}
} else {
  if(gemstone_typeof(#{name})==GS_TYPE_FIXNUM)
    fixnum_dispatch();
  else
    string_dispatch();
}
if(0) {
  #{self.compile_sexp([:send, :kernel, [[:pi_lit_str, "puts"], [:pi_lit_str, "message sent to value without dispatcher"]]])}
}

C
      elsif type == :ps_push_with_argstack_as_params
        "gs_stack_push_with_argstack_as_params();"
      
      elsif type == :ps_push_scope_argument
        num = self.compile_sexp [:pi_get_fixnum, primitive.shift]
        "gs_argstack_push((*gs_stack_pointer).parameters[#{num}]);"

      elsif type == :ps_dump_argstack
        "gs_argstack_dump();"

      elsif type == :ps_droparg
        "gs_argstack_pop();"


      elsif type == :ps_cast
        self.compile_sexp([:pb_block, primitive.shift, [:ps_droparg]])

      #
      # PRIMITIVE BLOCKS
      #
      elsif type == :pb_block
        primitive.map do |statement|
          self.compile_sexp(statement)
        end.join("\n")

      elsif type == :pb_if
        cond = self.compile_sexp(primitive.shift)
        then_code = self.compile_sexp(primitive.shift)
        else_code = self.compile_sexp(primitive.shift)
        "if(#{cond}) {\n#{then_code}\n} else { \n#{else_code}\n}\n"



      #
      # PRIMITIVE INLINES
      #
      elsif type == :pi_typeof
        arg = self.compile_sexp(primitive.shift)
        "gemstone_typeof(#{arg})"
      
      elsif type == :pi_c_equal
        left = self.compile_sexp(primitive.shift)
        right = self.compile_sexp(primitive.shift)
        "#{left} == #{right}"

      elsif type == :pi_cvar_get
        primitive.shift.to_s
      
      elsif type == :pi_lit_str
        str = primitive.shift
        raise 'need string' unless String === str
        "gs_string_literal(\"#{str}\", #{str.bytesize})"
      
      elsif type == :pi_lit_fixnum
        fixnum = primitive.shift
        fixnum = self.compile_sexp(fixnum) unless Fixnum === fixnum
        "gs_fixnum_literal(#{fixnum})"
      
      elsif type == :pi_c_const
        primitive.shift

      elsif type == :pi_get_str
        "(#{self.compile_sexp(primitive.shift)})->string"

      elsif type == :pi_get_fixnum
        "(#{self.compile_sexp(primitive.shift)})->fixnum"

      elsif type == :pi_stringvals_equal
        a = self.compile_sexp([:pi_get_str, primitive.shift])
        b = self.compile_sexp([:pi_get_str, primitive.shift])
        "strcmp(#{a}, #{b})==0"

      elsif type == :pi_get_result
        "(*gs_stack_pointer).result"

      elsif type == :pi_lvar_get
        n = self.compile_sexp([:pi_get_str, primitive.shift])
        "gs_lvars_fetch(#{n})"

      elsif type == :pi_poparg
        "gs_argstack_pop()"

      elsif type == :ps_pusharg
        what = self.compile_sexp(primitive.shift)
        "gs_argstack_push(#{what});"


      elsif type == :pi_get_inner_res
        "(gs_stack_pointer+1)->result"
      
      elsif type == :ps_kernel_dispatch
        "kernel_dispatch();"


      elsif type == :nop

      elsif type == :_raw
        primitive.shift





      elsif type == :send
        res = [:pb_block].concat Gemstone::Transformations::UnwindStack.apply(primitive)
        self.compile_sexp(res)


      else
        raise "unknown sexp type #{type} - #{primitive.inspect}"
      end
      @level -= 1
      log "=> #{val}", 3
      val
    end
  end
end