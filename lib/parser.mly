%{
    open Ast

    let string_of_ty_var = function
      | None -> None
      | Some (Ty_var s) -> Some s
      | _ -> failwith "Internal Error: Should have been a type var"
%}

%token Equal
%token Comma
%token Colon
%token Arrow
%token Dot
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
%token Type
%token Quote
%token MuchGreater

%nonassoc Less
%left Plus
%left Mult

%start <Ast.prog> prog

%%

prog: list(external_decl); list(typedef); expr; Eof
    { { external_decls = $1; typedefs = $2; expr = $3 } }

%inline external_decl:
  | External; Identifier; type_expr { $startpos, $2, $3 }

%inline typedef:
  | Type; option(poly_id); Identifier; Equal; Lbrac; separated_nonempty_list(Comma, type_decl); Rbrac
    { { poly_param = string_of_ty_var $2; name = $3; labels = $6; loc = $startpos } }

%inline type_decl:
  | Identifier; type_expr { $1, $2 }

expr:
  | Identifier { Var($startpos, $1) }
  | Int { Int($startpos, $1) }
  | bool { Bool($startpos, $1) }
  | expr; binop; expr { Bop($startpos, $2, $1, $3) }
  | If; expr; Then; expr; Else; expr { If($startpos, $2, $4, $6)}
  | decl; Equal; expr; expr { Let($startpos, $1, $3, $4) }
  | Function; Lpar; separated_list(Comma, decl); Rpar; option(return_annot); expr
    { Lambda($startpos, $3, $5, $6) }
  | Function; Identifier; Lpar; separated_list(Comma, decl); Rpar; option(return_annot); expr; expr
    { Function ($startpos, {name = $2; params = $4; return_annot = $6; body = $7; cont = $8}) }
  | expr; Lpar; separated_list(Comma, expr); Rpar { App($startpos, $1, $3) }
  | Lbrac; separated_nonempty_list(Comma, record_item); Rbrac { Record ($startpos, $2) }
  | expr; Dot; Identifier { Field ($startpos, $1, $3) }
  | expr; MuchGreater; expr { Sequence ($startpos, $1, $3) }

%inline record_item:
  | Identifier; Equal; expr { $1, $3 }

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

%inline return_annot:
  | Arrow; type_spec { $2 }

%inline type_expr:
  | Colon; type_spec; Arrow; type_spec  { [$2; $4] }
  | Colon; Lpar; separated_nonempty_list(Comma, type_func); Rpar; Arrow; type_spec  { $3 @ [$6] }
  | Colon; type_spec { [$2] }

%inline type_func:
  | type_spec; Arrow; type_spec  { Ty_expr [$1; $3] }
  | Lpar; separated_nonempty_list(Comma, type_spec); Rpar; Arrow; type_spec  { Ty_expr ($2 @ [$5]) }
  | type_spec { $1 }

%inline type_spec:
  | Identifier { Ty_id $1 }
  | poly_id { $1 }

%inline poly_id:
  | Quote; Identifier { Ty_var $2 }
