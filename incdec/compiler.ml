(* compiler.ml - compiler for epcp language 
   Modified from Ben Lerner's compiler from Lecture 2
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)
open Printf

type reg =
  | RAX

type arg =
  | Const of int64
  | Reg of reg

type instruction =
  | IMov of arg * arg

let reg_to_string (r : reg) : string =
  match r with
  | RAX -> "RAX"

let arg_to_string ( a : arg ) : string =
  match a with
  | Const entero -> Int64.to_string entero
  | Reg r -> reg_to_string r

let instr_to_string (i : instruction) : string =
  match i with
  | IMov (l, r) -> "mov " ^ arg_to_string l ^ ", " ^ arg_to_string r

let rec asm_to_string (asm : instruction list) : string =
  (* volvemos pronto *)
  match asm with
  | [] -> ""
  | a :: instrs -> instr_to_string a ^ asm_to_string instrs 




(* A very sophisticated compiler - insert the given integer into the mov
instruction at the correct place *)
(* esto esta roto!! *)
let compile (program : int64) : string =
  sprintf "
section .text
global our_code_starts_here
our_code_starts_here:
  mov RAX, %Ld
  ret\n" program;;

(* Some OCaml boilerplate for reading files and command-line arguments *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let lexbuf = Lexing.from_channel input_file in
  let input_program = Parser.expr Lexer.read lexbuf in
  close_in input_file;
  let program = (compile input_program) in
  printf "%s\n" program;;
