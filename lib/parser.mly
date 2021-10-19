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
%token Function

%nonassoc Less
%left Plus
%left Mult

%start <Ast.prog> prog

%%

prog: list(external_decl); expr; Eof { {external_decls = $1; typedefs = []; expr = $2} }

%inline external_decl:
  | External; Identifier; type_expr { $startpos, $2, $3 }

expr:
  | Identifier { Var($startpos, $1) }
  | Int { Int($startpos, $1) }
  | bool { Bool($startpos, $1) }
  | expr; binop; expr { Bop($startpos, $2, $1, $3) }
  | If; expr; Then; expr; Else; expr { If($startpos, $2, $4, $6)}
  | decl; Equal; expr; expr { Let($startpos, $1, $3, $4) }
  | Function; Lpar; separated_list(Comma, decl); Rpar; expr
    { Lambda($startpos, $3, $5) }
  | Function; decl; Lpar; separated_list(Comma, decl); Rpar; expr; expr
    { Function ($startpos, {name = $2; params = $4; body = $6; cont = $7}) }
  | expr; Lpar; separated_list(Comma, expr); Rpar { App($startpos, $1, $3) }

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
  | Colon; separated_nonempty_list(Arrow, Identifier);  { $2 }
