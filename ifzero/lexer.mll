(* lexer.mll - ocamllex source for lexer for epcp
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)
{
open Parser

exception SyntaxError of string
}

let int = '-'?['0'-'9']+
let letter = ['a'-'z' 'A'-'Z']
let identifiers = letter+

rule read =
     parse
     | [' ' '\t']+      { read lexbuf }
     | '\r' | '\n' | "\r\n" {  read lexbuf }
     | int { INT (Int64.of_string (Lexing.lexeme lexbuf)) }
     | '(' { LPAREN }
     | ')' { RPAREN }
     | "inc" { INC }
     | "dec" { DEC }
     | '+' { ADD }
     | '-' { SUB }
     | '*' { MULT }
     | "if"  { IF }
     | "let" { LET }
     | identifiers as id { ID id }
     | _ { raise (SyntaxError ("Illegal character - " ^ Lexing.lexeme lexbuf)) }
