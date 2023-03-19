(* syntax.ml - Abstract Syntax Tree for our compiler 
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)

type prim1 =
  | Inc
  | Dec

type 'a expr =
  | ENumber of int64 * 'a
  | EPrim1 of prim1 * 'a expr * 'a
  | EId of string * 'a
  | ELet of string * 'a expr * 'a expr * 'a
  | EIf of 'a expr * 'a expr * 'a expr * 'a
