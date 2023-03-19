(* interp.ml - Interpreter for  Abstract Syntax Tree for our language
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)

open Syntax

let rec lookup (x : string) (env : (string * int64) list) : int64  =
  match env with
  | [] -> failwith ("La " ^ x ^ " no está definida\n")
  | (id, n) :: env -> 
     if x = id then n else lookup x env

let interp ( e : expr ) : int64 =
  let rec helper (e, env) =
    match e with
    | Num n -> n
    | Inc e -> Int64.add (helper (e, env)) 1L
    | Dec e -> Int64.add (helper (e, env)) (-1L)
    | Id x -> (lookup x env)
    | Let (x, e, f) -> helper (f, (x, (helper (e, env))) :: env)
  in
  helper (e, [])

(* Some OCaml boilerplate for reading files and command-line arguments *)
let () =
  let input_file = (open_in (Sys.argv.(1))) in
  let lexbuf = Lexing.from_channel input_file in
  let input_program = Parser.expr Lexer.read lexbuf in
  close_in input_file;
  print_string (Int64.to_string (interp input_program))
