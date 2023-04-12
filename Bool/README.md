# Bool - a compiler that can almost compile "real" if expressions with Boolean conditions

This directory contains another broken compiler for if expressions. We've
got most of a parser made. I've refactored the compiler using code
from the [bolt
compiler](https://mukulrathi.com/create-your-own-programming-language/parsing-ocamllex-menhir/)
for lexing and parsing while tracking positions for better error
messages.

To do this we need to install some extra packages. If you see build errors like:
```
% dune build
File "dune", line 8, characters 19-22:
8 |    (libraries core fmt))
                       ^^^
Error: Library "fmt" not found.
-> required by _build/default/compiler.exe
-> required by alias all
-> required by alias default
```

Install the missing libraries with
```
$ opam install fmt core
```

After that, the new compiler can catch syntax errors:
```
$ make badinc.run
dune exec ./compiler.exe badinc.int > badinc.s
Done: 88% (38/43, 5 left) (jobs: 0)Line:1 Position:4: syntax error
make: *** [Makefile:13: badinc.s] Error 1
rm badinc.s
```

You can see the positions if you run the front end:

```
$ dune utop
utop # Front.parse_file (open_in "10.int");;
- : (Lexing.position expr, Core.Error.t) result =
Core.Ok
 (ENumber (10L,
   {Lexing.pos_fname = ""; pos_lnum = 1; pos_bol = 0; pos_cnum = 0}))
```
