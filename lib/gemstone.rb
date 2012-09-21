module Gemstone
  def self.compile(list_sexp, binary_path)

    compiler = Compiler.new
    main = compiler.compile_sexp(list_sexp)

    c = main

    #code = 
    wrapped = <<C
#include <stdio.h>
#include "gemstone.h"

#{compiler.lambdas.join("\n")}

void kernel_dispatch() {
  #{compiler.compile_kernel_dispatcher}
}

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

      elsif type == :send
        res = [:block].concat unwind_send_stack(primitive)
        self.compile_sexp(res)

      elsif type == :strings_equal
        a = self.compile_sexp([:getstring, primitive.shift])
        b = self.compile_sexp([:getstring, primitive.shift])
        "strcmp(#{a}, #{b})==0"
      
      elsif type == :lambda
        procedure = self.compile_sexp(primitive.shift)
        func = <<C

void mylambda(void) {
  INFO("inside lambda");

  #{procedure}

  INFO("lambda done");
}
C
        x =<<C
struct gs_value *the_lambda = malloc(sizeof(*the_lambda));
LOG("allocated lambda at  %llx", the_lambda);


memset(the_lambda, 0, sizeof(the_lambda));
the_lambda->type = GS_TYPE_LAMBDA;

the_lambda->lambda_func = &mylambda;

LOG("stack: %p ", gs_stack_pointer);
LOG("set lambda pointer to %llx", the_lambda->lambda_func );
LOG("while mylambda is at: %llx", mylambda);
gs_argstack_push(the_lambda);
C
        @lambdas << func
        x      
      elsif type == :jump_to_lambda
        x =<<C

LOG("stack: %p ", gs_stack_pointer);
LOG("jumping to lambda at %p", arg);
LOG("lambda gs_value type: %u", arg->type);

LOG("lambda pointer: %llx", arg->lambda_func );

arg->lambda_func();

INFO("lambda call done");

C
        x
      elsif type == :push
        "gs_stack_push();                           // >>>>>>>>>>>> #{primitive.shift}"
      elsif type == :pop
        "gs_stack_pop();                         // <<<<<<<<<<<<"

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
      #log "=> #{val}", 3
      val
    end

    def unwind_send_stack(node)
      node = node.dup
      target = node.shift
      steps = []
      raise 'can only send to kernel' if target != :kernel
      message_parts = node.shift.reverse

      steps << [:push]

      part_refs = message_parts.map do |part|
        if part.first == :send
          # Nested call
          part.shift

          @level += 1
          steps.concat unwind_send_stack(part)
          @level -= 1

          steps << [:pusharg, [:get_inner_res]]
        elsif part.first == :lambda
          steps << part
        else
          # Static call
          steps << [:pusharg, part]
        end

      end

      steps << [:kernel_dispatch]
      steps << [:pop]
      
      steps
    end

    def compile_kernel_dispatcher
      sexp = 
      [:block, 
        [:assign, :called_func, [:poparg]],
        [:assign, :arg, [:poparg]],

        [:raw, 'LOG("popd arg: %p", arg);'+"\n"],

        [:raw, 'LOG("running kernel call \'%s\'", called_func->string);'+"\n"],
        
        [:if, 
          [:strings_equal, [:lvar, :called_func], [:lit_str, "puts"]],
          [:call, :println, [:lvar, :arg]],
          [:if, 
            [:strings_equal, [:lvar, :called_func], [:lit_str, "typeof"]],
            [:call, :typeof, [:lvar, :arg]],
            [:if, 
              [:strings_equal, [:lvar, :called_func], [:lit_str, "returnstr"]],
              [:setres, [:lvar, :arg]],
              [:if, 
                [:strings_equal, [:lvar, :called_func], [:lit_str, "lvar_assign"]],
                [:block,
                  [:lvar_assign, [:lvar, :arg], [:poparg]],
                  [:setres, [:lvar, :arg]],
                ],
                [:if, 
                  [:strings_equal, [:lvar, :called_func], [:lit_str, "lvar_get"]],
                  [:setres, [:lvar_get, [:lvar, :arg]]],
                  [:if, 
                    [:strings_equal, [:lvar, :called_func], [:lit_str, "run_lambda"]],
                    [:jump_to_lambda, [:lvar, :arg]],
                    [:block,
                      [:call, :println, [:lit_str, "unknown kernel message:"]],
                      [:call, :println, [:lvar, :called_func]]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ],

        [:if,
          [:primitive_equal, [:getres], 0],
          [:setres, [:lit_str, "last inner call did not provide a return value"]],
          [:nop]
        ],

        [:raw, 'INFO("kernel dispatch complete");'+"\n"]
      ]

      self.compile_sexp(sexp)
    end
  end
end