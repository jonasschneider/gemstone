# Gemstone

This is an experimental implementation of a compiler backend from a Rubyish language to C. It's intended mainly as code excercise and demonstration of the awesomeness of pure TDD. Since it's a backend, it doesn't accept real syntax, but an AST-like Sexp, as input. The output is (horribly ugly) C that compiles (at least) on recent versions of OS X.

The specs show the complete development of the code, no code changes have been made without specing the expected results first. The specs, read in order, should represent the growing complexity of added features (with the occasional utility function sprinkled in).

## Synopsis

    $ irb -Ilib -rgemstone
    > Gemstone.compile [:call, :println, [:lit_str, "Hello world!"]], 'tmp/a.out'
    > exit
    $ tmp/a.out
    Hello world!

## License
Copyright 2012 Jonas Schneider.
Licensed under the MIT License.