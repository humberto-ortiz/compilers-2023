(* compiler.ml - compiler for ifzero language 
   Modified from Ben Lerner's compiler from Lecture 2, 3, and 4.
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
  | RegOffset (r, slot) -> "[" ^ reg_to_string r ^ " " ^ string_of_int slot ^ "]"

let instr_to_string (i : instruction) : string =
  match i with
  | IMov (l, r) -> "\tmov " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | IAdd (l, r) -> "\tadd " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | ICmp (l, r) -> "\tcmp " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | IJmp l -> "\tjmp " ^ l
  | IJe label -> "\tje " ^ label
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

type tag = int

let rec anf (e : tag expr)  : 'a aexpr =
  match e with
  | ENumber (n, tag) -> AImm (INumber (n, tag))
  | EPrim1 (op, e, tag) ->
     let varname = "_prim1" ^ (string_of_int tag) in
     ALet (varname, anf e, APrim1(op, IId (varname, tag), tag), tag)
  | EPrim2 (op, l, r, tag) ->
     let varname = "_prim2" ^ (string_of_int tag) in
     ALet (varname ^ "l", anf l, 
           ALet( varname ^ "r", anf r, 
                 APrim2 (op, IId (varname ^ "l", tag), IId (varname ^ "r", tag), tag) , tag), tag) 
  | EIf (c, t, e, tag) ->
     let varname = "_if" ^ (string_of_int tag) in
     ALet (varname, anf c, 
           AIf (IId (varname, tag), anf t, anf e, tag), tag)
  | ELet (v, i, b, tag) ->
     ALet (v, anf i, anf b, tag)
  | EId (v, tag) -> 
     AImm (IId (v, tag))

let rec compile_aexpr (e : tag aexpr) (env : env) : instruction list =
  let imm_to_arg imm =
    match imm with
      | INumber (n, _) ->  Const n
      | IId (id, _) -> RegOffset (RSP, ~-1 * 8 * (lookup id env) )
  in
  match e with
  | AImm imm -> [ IMov (Reg RAX, imm_to_arg imm) ]
  | APrim1 (Inc, e, _) ->  compile_aexpr (AImm e) env @ [ IAdd (Reg RAX, Const 1L) ]
  | APrim1 (Dec, e, _) -> compile_aexpr (AImm e) env @ [ IAdd (Reg RAX, Const (-1L)) ]
  | APrim2 (Plus, l, r, _) ->
     [ IMov (Reg RAX, imm_to_arg l) ;
       IAdd (Reg RAX, imm_to_arg r) ]
  | ALet (id, init, body, _) ->
     let (env', pos) = add id env in
     compile_aexpr init env @
       [ IMov (RegOffset (RSP, ~-1 * 8 * pos) , Reg RAX) ] @
         compile_aexpr body env'
  | AIf (c, t, e, tag) ->
     let lab1 = "segundo" ^ (string_of_int tag) in
     let lab2 = "end" ^ (string_of_int tag) in
      (compile_aexpr (AImm c) env)
    @ [ ICmp (Reg RAX, Const 0L) ;
        IJe lab1 ] 
    @    (compile_aexpr t env) @
           [ IJmp lab2 ; 
           ILabel lab1 ] @
             (compile_aexpr e env) @
               [ ILabel lab2 ]
  | _ -> failwith "No se compilar eso!"


let compile_prog (program : tag aexpr) : string =
  let instrs = compile_aexpr program [] in
  let asm_string = asm_to_string instrs in
  sprintf "
section .text
global our_code_starts_here
our_code_starts_here:
  %s
  ret\n" asm_string;;

let tag (e: 'a expr) : tag expr =
  let rec help (e : 'a expr) (cur : tag) : (tag expr * tag) =
    match e with
    | ENumber (n, _) ->
       (ENumber (n, cur), cur)
    | EPrim1(op, e, _) ->
      let (tag_e, next_tag) = help e (cur + 1) in
      (EPrim1(op, tag_e, cur), next_tag)
    | EPrim2(op, l, r, _) ->
       let (tag_l, left_tag) = help l (cur + 1) in
       let (tag_r, right_tag) = help r (left_tag + 1) in
       (EPrim2 (op, tag_l, tag_r, cur), right_tag)
    | EId (id, _) -> (EId (id, cur), cur)
    | ELet (id, init, body, _) ->
       let (tag_i, next_tag) = help init (cur + 1) in
       let (tag_b, next_tag) = help body (next_tag + 1) in
       (ELet (id, tag_i, tag_b, next_tag), next_tag)
    | EIf (c, thn, els, _) ->
      let (tag_c, next_tag) = help c (cur + 1) in
      let (tag_t, next_tag) = help thn (next_tag + 1) in
      let (tag_e, next_tag) = help els (next_tag + 1) in
        (EIf (tag_c, tag_t, tag_e, cur), next_tag)
    (* | _ -> failwith "No se tagear eso" *)
  in
  let (tagged, _) = help e 1 in tagged;;

(* Some OCaml boilerplate for reading files and command-line arguments *)
(* Use code from https://mukulrathi.com/create-your-own-programming-language/parsing-ocamllex-menhir/ to catch syntax errors *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let maybe_program = Front.parse_file input_file in
  close_in input_file;
  match maybe_program with
  | Ok input_program ->
     let tagged = tag input_program in
     let anfed = anf tagged in
     let program = (compile_prog anfed) in
     printf "%s\n" program
  | Error e -> eprintf "%s" (Core.Error.to_string_hum e) ; exit 1
