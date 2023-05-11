(* front.ml - parse programs and return AST or print a syntax error *)
(* Use code from https://mukulrathi.com/create-your-own-programming-language/parsing-ocamllex-menhir/ to print syntax errors *)

open Core
open Lexing
open Lexer

(* Prints the line number and character number where the error occurred.*)
let print_error_position lexbuf =
  let pos = lexbuf.lex_curr_p in
  Fmt.str "Line:%d Position:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)

let parse_program lexbuf =
  try Ok (Parser.program Lexer.read lexbuf) with
  (* catch exception and turn into Error *)
  | SyntaxError msg ->
      let error_msg = Fmt.str "%s: %s@." (print_error_position lexbuf) msg in
      Error (Error.of_string error_msg)
  | Parser.Error ->
      let error_msg = Fmt.str "%s: syntax error@." (print_error_position lexbuf) in
      Error (Error.of_string error_msg)

let parse_file (in_file) =
  let lexbuf = Lexing.from_channel in_file in
  parse_program lexbuf
