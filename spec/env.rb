require 'gemstone'

TEST_BINARY_PATH = 'tmp/a.out'

RSpec.configure do |c|
  c.before(:each) do
    File.unlink TEST_BINARY_PATH if File.exists? TEST_BINARY_PATH
  end

  def compile_and_execute(sexp)
    Gemstone.compile sexp, TEST_BINARY_PATH
    o = %x(#{TEST_BINARY_PATH})
    $stderr.puts o.inspect
    $?.exitstatus.should eq(0)
    o
  end

  def parse_and_run(code)
    sexp = Gemstone::Parser.parse(code)
    compile_and_execute(sexp)
  end

  def compile_and_execute_with_stderr(sexp)
    Gemstone.compile sexp, TEST_BINARY_PATH
    o = %x(#{TEST_BINARY_PATH} 2>&1)
    $?.exitstatus.should eq(0)
    o
  end
end
