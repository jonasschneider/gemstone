a = "some string"

def a.hello
  Gemstone.primitive :ps_hello_world
end

a.hello

# => "Hello world!\n"