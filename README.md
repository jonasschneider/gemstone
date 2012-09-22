# Gemstone [![Build Status](https://secure.travis-ci.org/jonasschneider/gemstone.png)](http://travis-ci.org/jonasschneider/gemstone)

This is an experimental implementation of a compiler for a dynamic, Ruby-like programming language, written in Ruby. It's intended primarily as a code excercise.

The compiler backend operates on a Sexp-like AST, and produces (horribly ugly) C that is is tested to compile on recent versions of OS X.

The frontend creating the AST is probably going use a Ruby-like syntax.

The specs show the complete development of the code. The specs, read in order, should represent the growing complexity of added features (with the occasional utility function sprinkled in).

## Synopsis

    $ irb -Ilib -rgemstone
    > Gemstone.compile [:call, :println, [:lit_str, "Hello world!"]], 'tmp/a.out'
    > exit
    $ tmp/a.out
    Hello world!

The generated code can be found in `tmp/code.c`.

## License
Unless otherwise noted: Copyright 2012 Jonas Schneider, dual-licensed under the GPLv3 and the MIT License.