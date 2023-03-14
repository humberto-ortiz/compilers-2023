# letcomp - a compiler that can almost compile let and identifiers

This directory contains a broken compiler for let and identifiers. We've got
most of a parser made, but it's missing your homework parser.

We can compile hand-built abstract syntax trees:

```
$ dune utop
utop # print_string (compile_prog (Let ("x", Num 1L, Inc (Id "x"))));;

section .text
global our_code_starts_here
our_code_starts_here:
  mov RAX, 1
mov [RSP -8], RAX
mov RAX, [RSP -8]
add RAX, 1

  ret
- : unit = ()
```
