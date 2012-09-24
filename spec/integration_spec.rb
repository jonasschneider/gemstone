require 'env'

describe Gemstone, "integration" do
  root = File.join(File.dirname(__FILE__), 'integration')
  
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