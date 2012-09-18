require 'rspec'
require 'gemstone'

describe Gemstone do
  let(:path_to_binary) { 'tmp/a.out' }
  
  before do
    File.unlink path_to_binary if File.exists? path_to_binary
  end

  def compile_and_execute(sexp)
    Gemstone.compile sexp, path_to_binary
    %x(#{path_to_binary})
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
    out = compile_and_execute [:send, :kernel, [:println, [:lit_str, "Hello world"]]]
    out.should eq("Hello world\n")
  end

  it "raises when trying to nest calls"

  it "shows the type of a string" do
    pending
    out = compile_and_execute [:block, [:assign, :string, [:lit_str, "Hello world"]], [:call, :println, [:call, :typeof, [:lvar, :string]]]]
    out.should eq("string\n")
  end

  it "shows the type of a number" do
    pending
    out = compile_and_execute [:block, [:assign, :num, 1337], [:call, :println, [:call, :typeof, [:lvar, :num]]]]
    out.should eq("fixnum\n")
  end

end