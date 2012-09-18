require 'rspec'
require 'gemstone'

describe Gemstone do
  def compile_and_execute(sexp)
    path_to_binary = Gemstone.compile sexp
    %x(#{path_to_binary})
  end

  it 'compiles a hello world' do
    out = compile_and_execute [:puts, "Hello world"]
    out.should eq("Hello world")
  end

  it 'compiles a hello world with another string' do
    out = compile_and_execute [:puts, "Hello my dear"]
    out.should eq("Hello my dear")
  end
end