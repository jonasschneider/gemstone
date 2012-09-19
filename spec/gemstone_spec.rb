require 'rspec'
require 'gemstone'

describe Gemstone do
  let(:path_to_binary) { 'tmp/a.out' }
  
  before do
    File.unlink path_to_binary if File.exists? path_to_binary
  end

  def compile_and_execute(sexp)
    Gemstone.compile sexp, path_to_binary
    o = %x(#{path_to_binary})
    $?.exitstatus.should eq(0)
    o
  end

  it 'compiles a hello world' do
    out = compile_and_execute [:call, :println, [:lit_str, "Hello world"]]
    out.should eq("Hello world\n")
  end

  it 'compiles a hello world with another string' do
    out = compile_and_execute [:call, :println, [:lit_str, "Hello my dear"]]
    out.should eq("Hello my dear\n")
  end

  it 'compiles a hello world in a block' do
    out = compile_and_execute [:block, [:call, :println, [:lit_str, "Hello my dear"]]]
    out.should eq("Hello my dear\n")
  end

  it 'compiles two hello worlds' do
    out = compile_and_execute [:block, [:call, :println, [:lit_str, "Hello my dear"]], [:call, :println, [:lit_str, "Bye now!"]]]
    out.should eq("Hello my dear\nBye now!\n")
  end

  it 'compiles a string assignment' do
    out = compile_and_execute [:block, [:assign, :string, [:lit_str, "Hello world"]], [:call, :println, [:lvar, :string]]]
    out.should eq("Hello world\n")
  end

  it 'fails when trying to printf a number' do
    out = compile_and_execute [:block, [:assign, :num, [:lit_fixnum, 1337]], [:call, :println, [:lvar, :num]]]
    out.should eq("Runtime error, expected string\n")
  end

  it "has a working if statement" do
    out = compile_and_execute [:if, 1, [:call, :println, [:lit_str, "true"]], [:call, :println, [:lit_str, "false"]]]
    out.should eq("true\n")

    out = compile_and_execute [:if, 0, [:call, :println, [:lit_str, "true"]], [:call, :println, [:lit_str, "false"]]]
    out.should eq("false\n")
  end

  it "can check for primitive equality" do
    out = compile_and_execute [:if, [:primitive_equal, 1, 1], [:call, :println, [:lit_str, "true"]], [:call, :println, [:lit_str, "false"]]]
    out.should eq("true\n")

    out = compile_and_execute [:if, [:primitive_equal, 0, 1], [:call, :println, [:lit_str, "true"]], [:call, :println, [:lit_str, "false"]]]
    out.should eq("false\n")
  end

  it "can send messages to kernel" do
    out = compile_and_execute [:send, :kernel, [[:lit_str, "puts"], [:lit_str, "Hello world"]]]
    out.should eq("Hello world\n")
  end

  it "can send nested messages to kernel" do
    out = compile_and_execute [:send, :kernel, [[:lit_str, "puts"], [:send, :kernel, [[:lit_str, "returnstr"], [:lit_str, "Stackstring"]]]]]
    out.should eq("Stackstring\n")
  end

  it "can unwind_send_stack" do
    r = Gemstone::Compiler.new.unwind_send_stack [:kernel, [[:lit_str, "puts"], [:send, :kernel, [[:lit_str, "returnstr"], [:lit_str, "Stackstring"]]]]]
    r.should == [
      [:push],
      [:push],

      [:pusharg, [:lit_str, "Stackstring"]],
      [:pusharg, [:lit_str, "returnstr"]],
      [:kernel_dispatch],

      [:pop],

      [:pusharg, [:get_inner_res]],
      [:pusharg, [:lit_str, "puts"]],
      [:kernel_dispatch],

      [:pop]
    ]
  end

  it "runs puts from stack" do
    out = compile_and_execute [:block,
      [:push],
      [:pusharg, [:lit_str, "Stackstring"]],
      [:pusharg, [:lit_str, "puts"]],
      [:kernel_dispatch]
    ]
    out.should eq("Stackstring\n")
  end

  it "runs puts from stack with argument from deeper within" do
    out = compile_and_execute [:block,
      [:push],
      [:push],

      [:pusharg, [:lit_str, "Stackstring"]],
      [:pusharg, [:lit_str, "returnstr"]],
      [:kernel_dispatch],

      [:pop],

      [:pusharg, [:get_inner_res]],
      [:pusharg, [:lit_str, "puts"]],
      [:kernel_dispatch]
    ]
    out.should eq("Stackstring\n")
  end

  it "sets a default message when the dispatched action does not set a return value" do
    out = compile_and_execute [:block,
      [:push],
      [:push],

      [:pusharg, [:lit_str, "some string"]],
      [:pusharg, [:lit_str, "puts"]],
      [:kernel_dispatch],

      [:pop],

      [:pusharg, [:get_inner_res]],
      [:pusharg, [:lit_str, "puts"]],
      [:kernel_dispatch]
    ]
    out.should eq("some string\nlast inner call did not provide a return value\n")
  end

  it "can compare strings" do
    out = compile_and_execute [:block, 
        [:lvar_assign, :a, [:lit_str, "Hello world"]],
        [:lvar_assign, :b, [:lit_str, "Hello world"]],
        [:if, [:strings_equal, [:lvar_get, :a], [:lvar_get, :b]], [:call, :println, [:lit_str, "match"]], [:call, :println, [:lit_str, "no match"]]]]
    out.should eq("match\n")

    out = compile_and_execute [:block, 
        [:lvar_assign, :a, [:lit_str, "Hello world"]],
        [:lvar_assign, :b, [:lit_str, "Bye world"]],
        [:if, [:strings_equal, [:lvar_get, :a], [:lvar_get, :b]], [:call, :println, [:lit_str, "match"]], [:call, :println, [:lit_str, "no match"]]]]
    out.should eq("no match\n")
  end

  it "shows the type of a string" do
    out = compile_and_execute [:send, :kernel, [[:lit_str, "puts"], [:send, :kernel, [[:lit_str, "typeof"], [:lit_str, "Stackstring"]]]]]
    out.should eq("string\n")
  end

  it "shows the type of a number" do
    out = compile_and_execute [:send, :kernel, [[:lit_str, "puts"], [:send, :kernel, [[:lit_str, "typeof"], [:lit_fixnum, 1337]]]]]
    out.should eq("fixnum\n")
  end

end