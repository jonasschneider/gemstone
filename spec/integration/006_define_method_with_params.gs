a = 'a string'

def a.say(what, to_whom)
  puts what
  puts to_whom
  puts "!"
end

a.say "hello", "world"

# => "hello\nworld\n!\n"