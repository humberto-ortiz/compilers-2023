/* parser.mly - menhir source for parser for epcp programs 
   Copyright (2023) Humberto Ortiz-Zuazaga <humberto.ortiz@upr.edu>
   See LICENSE for details
*/
%token <int64> INT
%token <string> ID
%token LPAREN
%token RPAREN
%token INC
%token DEC
%token ADD
%token SUB
%token MULT
%token IF
%token LET

%start <'a Syntax.expr> expr
%%

expr:
  | i = INT { ENumber (i, $startpos) }
  | LPAREN INC e = expr RPAREN { EPrim1 (Inc, e, $startpos) }
  | LPAREN DEC e = expr RPAREN { EPrim1 (Dec, e, $startpos) }
  | LPAREN l = expr ADD r = expr RPAREN { EPrim2 (Plus, l, r, $startpos) }
  | LPAREN l = expr SUB r = expr RPAREN { EPrim2 (Minus, l, r, $startpos) }
  | LPAREN l = expr MULT r = expr RPAREN { EPrim2 (Times, l, r, $startpos) }
  | LPAREN IF c = expr t = expr e = expr RPAREN { EIf (c, t, e, $startpos) }
  | LPAREN LET id = ID init = expr body = expr RPAREN { ELet (id, init, body, $startpos) }
  | id = ID { Syntax.EId (id, $startpos) }
