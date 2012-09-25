a = 'a string'

def a.hello_to(whom)
  puts "hello"
  puts whom
end

a.hello_to "world"

# => "hello\nworld\n"