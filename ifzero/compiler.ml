(* compiler.ml - compiler for epcp language 
   Modified from Ben Lerner's compiler from Lecture 2
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)
open Printf
open Syntax

type reg =
  | RAX
  | RSP

type arg =
  | Const of int64
  | Reg of reg
  | RegOffset of reg * int

type instruction =
  | IMov of arg * arg
  | IAdd of arg * arg
  | ICmp of arg * arg
  | IJmp of string
  | IJe of string
  | ILabel of string

let reg_to_string (r : reg) : string =
  match r with
  | RAX -> "RAX"
  | RSP -> "RSP"

let arg_to_string ( a : arg ) : string =
  match a with
  | Const entero -> Int64.to_string entero
  | Reg r -> reg_to_string r
  | RegOffset (r, o) -> "[" ^ (reg_to_string r) ^ " " ^ (string_of_int o) ^ "]"

let instr_to_string (i : instruction) : string =
  match i with
  | IMov (l, r) -> "mov " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | IAdd (l, r) -> "add " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | ICmp (l, r) -> "cmp " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | IJmp l -> "jmp " ^ l
  | IJe label -> "je " ^ label
  | ILabel label -> label ^ ":"

let rec asm_to_string (asm : instruction list) : string =
  (* volvemos pronto *)
  match asm with
  | [] -> ""
  | a :: instrs -> instr_to_string a ^ "\n" ^ asm_to_string instrs 

type env = (string * int) list

let rec lookup name env =
  match env with
  | [] -> failwith ("No se encontro " ^ name ^ "\n")
  | (id, i)::rest -> if id = name then i else (lookup name rest) 

let add name env =
  let slot = 1 + (List.length env) in
  ((name, slot)::env, slot)

let rec compile_expr (e : expr) (env : env) : instruction list =
  match e with
  | Num n -> [ IMov (Reg RAX, Const n) ]
  | Inc e -> compile_expr e env @ [ IAdd (Reg RAX, Const 1L) ] 
  | Dec e -> compile_expr e env @ [ IAdd (Reg RAX, Const (-1L)) ]
  | Id x -> [ IMov (Reg RAX, RegOffset (RSP, ~-1 * 8 * (lookup x env) )) ]
  | Let (x, i, d) -> 
     let (env', pos) = add x env in
     compile_expr i env @
       [ IMov (RegOffset (RSP, ~-1 * 8 * pos) , Reg RAX) ] @
         compile_expr d env'
  | If (e1, e2, e3) ->
     (compile_expr e1 env) @
       [ ICmp (Reg RAX, Const 0L) ;
         IJe "segundo" ] @
         (compile_expr e2 env) @
           [ IJmp "end" ; 
           ILabel "segundo" ] @
             (compile_expr e3 env) @
               [ ILabel "end" ]
  (* | _ -> failwith "No se compilar eso" *)

let compile_prog (program : expr) : string =
  let instrs = compile_expr program [] in
  let asm_string = asm_to_string instrs in
  sprintf "
section .text
global our_code_starts_here
our_code_starts_here:
  %s
  ret\n" asm_string;;

(* Some OCaml boilerplate for reading files and command-line arguments *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let lexbuf = Lexing.from_channel input_file in
  let input_program = Parser.expr Lexer.read lexbuf in
  close_in input_file;
  let program = (compile_prog input_program) in
  printf "%s\n" program;;
