%{
    open Ast
%}

%token Equal
%token Comma
%token Colon
%token Arrow
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
%token External

%nonassoc Less
%left Plus
%left Mult

%start <Ast.prog> prog

%%

prog: list(external_decl); expr; Eof { $1, $2 }

%inline external_decl:
  | External; Identifier; type_expr { $startpos, $2, $3 }

expr:
  | Identifier { Var($startpos, $1) }
  | Int { Int($startpos, $1) }
  | bool { Bool($startpos, $1) }
  | expr; binop; expr { Bop($startpos, $2, $1, $3) }
  | If; expr; Then; expr; Else; expr { If($startpos, $2, $4, $6)}
  | decl; Equal; expr; expr { Let($startpos, $1, $3, $4) }
  | Lbrac; decl; Dot; expr; Rbrac { Abs($startpos, $2, $4) }
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

%inline decl:
  | Identifier; option(type_expr) { $1, $2 }

%inline type_expr:
  | Colon; Identifier { Atom_type $2 }
  | Colon; Identifier; Arrow; Identifier { Fun_type ($2, $4) }
