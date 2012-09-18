require 'rspec'
require 'gemstone'

describe Gemstone do
  it 'compiles a hello world' do
    code = [:puts, "Hello world"]
    path_to_binary = Gemstone.compile code
    output = %x(#{path_to_binary})
    output.should eq("Hello world")
  end
end