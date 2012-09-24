require 'gemstone'

describe Gemstone, "integration" do
  let(:path_to_binary) { 'tmp/a.out' }
  root = File.join(File.dirname(__FILE__), 'integration')
  
  before do
    File.unlink path_to_binary if File.exists? path_to_binary
  end

  def compile_and_execute(sexp)
    Gemstone.compile sexp, path_to_binary
    o = %x(#{path_to_binary})
    p o
    $?.exitstatus.should eq(0)
    o
  end

  def parse_and_run(code)
    sexp = Gemstone::Parser.parse(code)
    compile_and_execute(sexp)
  end

  Dir[root + "/*.gs"].each do |path|
    it "correctly runs #{path}" do
      code = File.read(path)
      if code.match(/^# => ([^\n]+)$/)
        expected_out = eval($1)
        parse_and_run(code).should == expected_out
      else
        raise "could not extract expected output"
      end
    end
  end
end