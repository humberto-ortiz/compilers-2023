/* parser.mly - menhir source for parser for epcp programs 
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*/
%token <int64> INT
%token <string> ID
%token <bool> BOOL
%token LPAREN
%token RPAREN
%token INC
%token DEC
%token ADD
%token SUB
%token MULT
%token GREATER
%token IF
%token LET
%token DEF

%start <'a Syntax.program> program
%%

program:
  | e = expr { Program ([], e) }
  | ds = decls e = expr { Program (ds, e) }

decls:
  | d = decl { [d] }
  | d = decl ds = decls { d :: ds }

decl:
  | LPAREN DEF f = ID a = ID b = expr RPAREN
    { DFun (f, a, b, $startpos) }

expr:
  | i = INT { ENumber (i, $startpos) }
  | i = BOOL { EBool (i, $startpos) }
  | LPAREN e = expr GREATER r = expr RPAREN { EPrim2 (Greater , e, r, $startpos) }
  | LPAREN INC e = expr RPAREN { EPrim1 (Inc, e, $startpos) }
  | LPAREN DEC e = expr RPAREN { EPrim1 (Dec, e, $startpos) }
  | LPAREN l = expr ADD r = expr RPAREN { EPrim2 (Plus, l, r, $startpos) }
  | LPAREN l = expr SUB r = expr RPAREN { EPrim2 (Minus, l, r, $startpos) }
  | LPAREN l = expr MULT r = expr RPAREN { EPrim2 (Times, l, r, $startpos) }
  | LPAREN IF c = expr t = expr e = expr RPAREN { EIf (c, t, e, $startpos) }
  | LPAREN LET id = ID init = expr body = expr RPAREN { ELet (id, init, body, $startpos) }
  | LPAREN f = ID a = expr RPAREN { EApp (f, a, $startpos) }
  | id = ID { Syntax.EId (id, $startpos) }
