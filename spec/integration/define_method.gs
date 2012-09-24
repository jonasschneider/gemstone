a = "some string"

def a.hello
  Gemstone.primitive :ps_hello_world
  Gemstone.primitive :ps_hello_world
end

a.hello

# => "Hello world!\nHello world!\n"