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
%token Minus
%token Mult
%token Less
%token Bin_equal
%token Lpar
%token Rpar
%token Lbrac
%token Rbrac
%token If
%token Then
%token Else
%token Eof

%nonassoc Less
%left Plus
%left Mult

%start <Ast.expr> prog

%%

prog: expr; Eof { $1 }

expr:
  | Identifier { Var($startpos, $1) }
  | Int { Int($startpos, $1) }
  | bool { Bool($startpos, $1) }
  | expr; binop; expr { Bop($startpos, $2, $1, $3) }
  | If; expr; Then; expr; Else; expr { If($startpos, $2, $4, $6)}
  | identifier; Equal; expr; expr { Let($startpos, $1, $3, $4) }
  | Lbrac; identifier; Dot; expr; Rbrac { Abs($startpos, $2, $4) }
  | expr; Lpar; expr; Rpar { App($startpos, $1, $3) }

bool:
  | True { true }
  | False { false }

%inline binop:
  | Plus  { Plus }
  | Minus { Minus }
  | Mult  { Mult }
  | Less  { Less }
  | Bin_equal { Equal }

%inline identifier:
  | Identifier { $1, None }
  | Identifier; Colon; Identifier { $1, Some $3 }
