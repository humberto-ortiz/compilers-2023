(* syntax.ml - Abstract Syntax Tree for our compiler 
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*)

type expr =
  | Num of int64
  | Inc of expr
  | Dec of expr
