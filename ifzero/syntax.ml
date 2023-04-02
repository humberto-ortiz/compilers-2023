(* syntax.ml - Abstract Syntax Tree for our compiler 
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)

type prim1 =
  | Inc
  | Dec

type prim2 =
  | Plus
  | Minus
  | Times

type 'a expr =
  | ENumber of int64 * 'a
  | EPrim1 of prim1 * 'a expr * 'a
  | EPrim2 of prim2 * 'a expr * 'a expr * 'a
  | EId of string * 'a
  | ELet of string * 'a expr * 'a expr * 'a
  | EIf of 'a expr * 'a expr * 'a expr * 'a

type 'a immexpr =
  | INumber of int64 * 'a
  | IId of string * 'a

type 'a aexpr =
  | AImm of 'a immexpr
  | APrim1 of prim1 * 'a immexpr * 'a
  | APrim2 of prim2 * 'a immexpr * 'a immexpr * 'a
  | ALet of string * 'a aexpr * 'a aexpr * 'a
  | AIf of 'a immexpr * 'a aexpr * 'a aexpr * 'a
