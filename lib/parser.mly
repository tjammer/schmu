%{
    open Ast
%}

%token Equal
%token Comma
%token Colon
%token Dot
%token Backslash
%token <string> Identifier
%token <int> Int
%token True
%token False
%token Plus
%token Mult
%token Less
%token Bin_equal
%token Lpar
%token Rpar
%token If
%token Eof

%start <Ast.expr> prog

%%

prog: expr; Eof { $1 }

expr:
  | Identifier { Var($startpos, $1) }
  | Int { Int($startpos, $1) }
  | bool { Bool($startpos, $1) }
  | expr; binop; expr { Bop($startpos, $2, $1, $3) }
  | If; expr; expr; expr { If($startpos, $2, $3, $4)}
  | Identifier; Equal; expr; expr { Let($startpos, $1, $3, $4) }
  | Backslash; Identifier; Dot; expr { Abs($startpos, $2, $4) }
  | expr; Lpar; expr; Rpar { App($startpos, $1, $3) }

bool:
  | True { true }
  | False { false }

binop:
  | Plus { Plus }
  | Mult { Mult }
  | Less { Less }
  | Bin_equal { Equal }
