(* pretty.ml - pretty printer for syntax
   Copyright (2023) - Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details.
*)

open Syntax

let rec pretty e =
  match e with
  | Num n -> Int64.to_string n
  | Inc e -> "Inc " ^ pretty e
  | Dec e -> "Dec " ^ pretty e
  | Id x -> x
  | Let (x, e, b) -> x ^ pretty e ^ pretty b

(* Some OCaml boilerplate for reading files and command-line arguments *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let lexbuf = Lexing.from_channel input_file in
  let input_program = Parser.expr Lexer.read lexbuf in
  close_in input_file;
  print_string (pretty input_program)
