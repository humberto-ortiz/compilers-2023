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
  | RDI
  | RBP

type arg =
  | Const of int64
  | Reg of reg
  | RegOffset of reg * int

type instruction =
  | IMov of arg * arg
  | IAdd of arg * arg
  | ICmp of arg * arg
  | ITest of arg * arg
  | IJmp of string
  | IJnz of string
  | IJe of string
  | ILabel of string
  | ICall of string
  | IRet
  | IPush of arg
  | IPop of arg

let reg_to_string (r : reg) : string =
  match r with
  | RAX -> "RAX"
  | RSP -> "RSP"
  | RDI -> "RDI"
  | RBP -> "RBP"

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
  | ITest (l, r) -> "\ttest " ^ arg_to_string l ^ ", " ^ arg_to_string r
  | IJmp l -> "\tjmp " ^ l
  | IJnz l -> "\tjnz " ^ l
  | IJe label -> "\tje " ^ label
  | ILabel label -> label ^ ":"
  | ICall label -> "\tcall " ^ label
  | IRet -> "\tret"
  | IPush a -> "\tpush " ^ arg_to_string a
  | IPop a -> "\tpop " ^ arg_to_string a

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
  | EBool (b, tag) -> AImm (IBool (b, tag))
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
  | EApp (f, a, tag) -> 
     let varname = "_app" ^ (string_of_int tag) in
       ALet (varname ^ "a", anf a,
         AApp (f, IId (varname ^ "a", tag), tag), tag) 

let anf_program (p : 'a program) : 'a aprogram =
  let help d =
    match d with
    | DFun (f, a, b, tag) -> AFun (f, a, anf b, tag)
  in
  match p with
  | Program (ds, e) -> AProgram (List.map help ds, anf e) 

let const_true  = 0xFFFFFFFFFFFFFFFFL
let const_false = 0x7FFFFFFFFFFFFFFFL
let min_cobra_int = Int64.div Int64.min_int 2L
let max_cobra_int = Int64.div Int64.max_int 2L

let rec compile_aexpr (e : tag aexpr) (env : env) : instruction list =
  let imm_to_arg imm =
    match imm with
      | INumber (n, _) ->  
         if (n < min_cobra_int || n > max_cobra_int ) then
           failwith ("Integer overflow " ^ (Int64.to_string n))
         else
           Const (Int64.mul n  2L)
      | IBool (false, _) -> Const const_false
      | IBool (true, _) -> Const const_true
      | IId (id, _) -> RegOffset (RSP, ~-1 * 8 * (lookup id env) )
  in
  match e with
  | AImm imm -> [ IMov (Reg RAX, imm_to_arg imm) ]
  | APrim1 (Inc, e, _) ->  compile_aexpr (AImm e) env 
                           @ [ ITest (Reg RAX, Const 0x01L) ;
                               IJnz "error_not_number" ;
                               IAdd (Reg RAX, Const 2L) ]
  | APrim1 (Dec, e, _) -> compile_aexpr (AImm e) env 
                          @ [  ITest (Reg RAX, Const 0x01L) ;
                               IJnz "error_not_number" ;
                               IAdd (Reg RAX, Const (-2L)) ]
  | AApp (f, a, _) ->
     compile_aexpr (AImm a) env @
       [ IMov (Reg RDI, Reg RAX) ;
         ICall f ]
  | APrim2 (Plus, l, r, _) ->
     [ IMov (Reg RAX, imm_to_arg l) ;
       IAdd (Reg RAX, imm_to_arg r) ]
  | APrim2 (Greater, l, r, _) ->
     [ IMov (Reg RAX, imm_to_arg l) ;
       ICmp (Reg RAX, imm_to_arg r) ]

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

let compile_def d =
  match d with
      | AFun (f, a, body, _) ->
         let (env', _) = add a [] in
         [ ILabel f ;
           IPush (Reg RBP) ;
           IMov (Reg RBP, Reg RSP) ;
           IMov (RegOffset (RSP, ~-1 * 8 * 1) , Reg RDI)
         ] @
           compile_aexpr body env' @
             [ IMov (Reg RSP, Reg RBP);
               IPop (Reg RBP);
               IRet ]

let compile_defs ds =
  List.map compile_def ds

let compile_prog (program : tag aprogram) : string =
  match program with
| AProgram (ds, e) ->
  let compiled_defs = compile_defs ds in
  let defs_string = asm_to_string (List.flatten compiled_defs) in
  let instrs = compile_aexpr e [] in
  let asm_string = asm_to_string instrs in
  sprintf "
section .text
extern error
extern print
global our_code_starts_here
our_code_starts_here:
  push RBP          ; save (previous, caller's) RBP on stack
  mov RBP, RSP      ; make current RSP the new RBP
  %s
  mov RSP, RBP      ; restore value of RSP to that just before call
                  ; now, value at [RSP] is caller's (saved) RBP
  pop RBP           ; so: restore caller's RBP from stack [RSP]
  ret

; Nuestras funciones
%s

error_not_number:
  mov RDI, 1
  mov RSI, RAX
  jmp error
\n" asm_string defs_string;;

let tag_program (p : 'a program) : tag program =
  let  rec tag_expr (e : 'a expr) (cur : tag) : (tag expr * tag) =
    match e with
    | ENumber (n, _) ->
       (ENumber (n, cur), cur)
    | EBool (b, _) -> (EBool (b, cur), cur)
    | EPrim1(op, e, _) ->
       let (tag_e, next_tag) = tag_expr e (cur + 1) in
       (EPrim1(op, tag_e, cur), next_tag)
    | EPrim2(op, l, r, _) ->
       let (tag_l, left_tag) = tag_expr l (cur + 1) in
       let (tag_r, right_tag) = tag_expr r (left_tag + 1) in
       (EPrim2 (op, tag_l, tag_r, cur), right_tag)
    | EId (id, _) -> (EId (id, cur), cur)
    | ELet (id, init, body, _) ->
       let (tag_i, next_tag) = tag_expr init (cur + 1) in
       let (tag_b, next_tag) = tag_expr body (next_tag + 1) in
       (ELet (id, tag_i, tag_b, next_tag), next_tag)
    | EIf (c, thn, els, _) ->
       let (tag_c, next_tag) = tag_expr c (cur + 1) in
       let (tag_t, next_tag) = tag_expr thn (next_tag + 1) in
       let (tag_e, next_tag) = tag_expr els (next_tag + 1) in
       (EIf (tag_c, tag_t, tag_e, cur), next_tag)
    | EApp (f, a, _) ->
       let (tag_a, next_tag) = tag_expr a (cur + 1) in
       (EApp (f, tag_a, cur), next_tag)
  (* | _ -> failwith "No se tagear eso" *)
  and  tag_dfun (d : 'a decl) (cur : tag) : (tag decl * tag) =
    match d with
    | DFun (f, a, b, _) -> 
       let (tagged, next_tag) = tag_expr b (cur + 1) in
       (DFun (f, a, tagged, next_tag), next_tag)


  in
  match p with
  | Program (ds, e) -> 
     let rec help (ds, cur) =
       match ds with
       | [] -> ([], cur)
       | d :: ds -> 
          let next_tag = cur + 1 in
          let (tagged_d, next_tag) = tag_dfun d next_tag in
          let (tagged_ds, next_tag) = help (ds, next_tag) in
          (tagged_d :: tagged_ds, next_tag)
     in
     let (tagged_ds, next_tag) = help (ds, 1) in
     let (tagged_e, _) = tag_expr e next_tag in
     Program (tagged_ds, tagged_e)

(* Some OCaml boilerplate for reading files and command-line arguments *)
(* Use code from https://mukulrathi.com/create-your-own-programming-language/parsing-ocamllex-menhir/ to catch syntax errors *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let maybe_program = Front.parse_file input_file in
  close_in input_file;
  match maybe_program with
  | Ok input_program ->
     let tagged = tag_program input_program in
     let anfed = anf_program tagged in
     let program = (compile_prog anfed) in
     printf "%s\n" program
  | Error e -> eprintf "%s" (Core.Error.to_string_hum e) ; exit 1
