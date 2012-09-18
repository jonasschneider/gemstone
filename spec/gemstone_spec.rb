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
    out = compile_and_execute [:call, :puts, "Hello world"]
    out.should eq("Hello world\n")
  end

  it 'compiles a hello world with another string' do
    out = compile_and_execute [:call, :puts, "Hello my dear"]
    out.should eq("Hello my dear\n")
  end

  it 'compiles a hello world in a block' do
    out = compile_and_execute [:block, [:call, :puts, "Hello my dear"]]
    out.should eq("Hello my dear\n")
  end

  it 'compiles two hello worlds' do
    out = compile_and_execute [:block, [:call, :puts, "Hello my dear"], [:call, :puts, "Bye now!"]]
    out.should eq("Hello my dear\nBye now!\n")
  end

  it 'compiles a string assignment' do
    out = compile_and_execute [:block, [:assign, :string, "Hello world"], [:call, :puts, [:lvar, :string]]]
    out.should eq("Hello world\n")
  end

  it 'fails when trying to printf a number' do
    pending
    out = compile_and_execute [:block, [:assign, :num, 1337], [:call, :puts, [:lvar, :num]]]
    out.should eq("Hello world\n")
  end

  it "shows the type of a string" do
    pending
    out = compile_and_execute [:block, [:assign, :string, "Hello world"], [:call, :puts, [:call, :typeof, [:lvar, :string]]]]
    out.should eq("string\n")
  end

  it "has a working if statement" do
    out = compile_and_execute [:if, 1, [:call, :puts, "true"], [:call, :puts, "false"]]
    out.should eq("true\n")

    out = compile_and_execute [:if, 0, [:call, :puts, "true"], [:call, :puts, "false"]]
    out.should eq("false\n")
  end
end