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
