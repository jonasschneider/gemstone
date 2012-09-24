require 'gemstone'

describe Gemstone, "primitives" do
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

  def compile_and_execute_with_stderr(sexp)
    Gemstone.compile sexp, path_to_binary
    o = %x(#{path_to_binary} 2>&1)
    $?.exitstatus.should eq(0)
    o
  end

  it 'compiles a hello world' do
    out = compile_and_execute [:ps_print, [:pi_lit_str, "Hello world"]]
    out.should eq("Hello world\n")
  end

  it 'compiles a hello_world primitive' do
    out = compile_and_execute [:ps_hello_world]
    out.should eq("Hello world!\n")
  end

  it 'compiles a hello world with another string' do
    out = compile_and_execute [:ps_print, [:pi_lit_str, "Hello my dear"]]
    out.should eq("Hello my dear\n")
  end

  it 'compiles a hello world in a block' do
    out = compile_and_execute [:pb_block, [:ps_print, [:pi_lit_str, "Hello my dear"]]]
    out.should eq("Hello my dear\n")
  end

  it 'compiles two hello worlds' do
    out = compile_and_execute [:pb_block, 
      [:ps_print, [:pi_lit_str, "Hello my dear"]],
      [:ps_print, [:pi_lit_str, "Bye now!"]]
    ]
    out.should eq("Hello my dear\nBye now!\n")
  end

  it 'compiles a string assignment' do
    out = compile_and_execute [:pb_block, 
      [:ps_cvar_assign, 'string', [:pi_lit_str, "Hello world"]],
      [:ps_print, [:pi_cvar_get, 'string']]
    ]
    out.should eq("Hello world\n")
  end

  it "has a working if statement" do
    out = compile_and_execute [:pb_if, 1, [:ps_print, [:pi_lit_str, "true"]], [:ps_print, [:pi_lit_str, "false"]]]
    out.should eq("true\n")

    out = compile_and_execute [:pb_if, 0, [:ps_print, [:pi_lit_str, "true"]], [:ps_print, [:pi_lit_str, "false"]]]
    out.should eq("false\n")
  end

  it "can check for primitive equality" do
    out = compile_and_execute [:pb_if, [:pi_c_equal, 1, 1], [:ps_print, [:pi_lit_str, "true"]], [:ps_print, [:pi_lit_str, "false"]]]
    out.should eq("true\n")

    out = compile_and_execute [:pb_if, [:pi_c_equal, 0, 1], [:ps_print, [:pi_lit_str, "true"]], [:ps_print, [:pi_lit_str, "false"]]]
    out.should eq("false\n")
  end

  it "can compare strings" do
    out = compile_and_execute [:pb_block, 
        [:ps_cvar_assign, 'a', [:pi_lit_str, "Hello world"]],
        [:ps_cvar_assign, 'b', [:pi_lit_str, "Hello world"]],
        [:pb_if, [:pi_stringvals_equal, [:pi_cvar_get, 'a'], [:pi_cvar_get, 'b']], [:ps_print, [:pi_lit_str, "match"]], [:ps_print, [:pi_lit_str, "no match"]]]]
    out.should eq("match\n")

    out = compile_and_execute [:pb_block, 
        [:ps_cvar_assign, 'a', [:pi_lit_str, "Hello world"]],
        [:ps_cvar_assign, 'b', [:pi_lit_str, "Bye world"]],
        [:pb_if, [:pi_stringvals_equal, [:pi_cvar_get, 'a'], [:pi_cvar_get, 'b']], [:ps_print, [:pi_lit_str, "match"]], [:ps_print, [:pi_lit_str, "no match"]]]]
    out.should eq("no match\n")

    # Check if it still works when the first string is shorter
    out = compile_and_execute [:pb_block, 
        [:ps_cvar_assign, 'a', [:pi_lit_str, "Hello"]],
        [:ps_cvar_assign, 'b', [:pi_lit_str, "Bye world"]],
        [:pb_if, [:pi_stringvals_equal, [:pi_cvar_get, 'a'], [:pi_cvar_get, 'b']], [:ps_print, [:pi_lit_str, "match"]], [:ps_print, [:pi_lit_str, "no match"]]]]
    out.should eq("no match\n")
  end

  it 'can dump the current argstack' do
    out = compile_and_execute_with_stderr [:pb_block, 
      [:ps_pusharg, [:pi_lit_str, "first pushed"]],
      [:ps_pusharg, [:pi_lit_fixnum, 2]],
      [:ps_pusharg, [:pi_lit_str, "third pushed"]],
      [:ps_dump_argstack]
    ]
    out.should include("<string> third pushed\n")
    out.should include("<fixnum> 2\n")
    out.should include("<string> first pushed\n")
  end
end