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
%token End

%nonassoc Less
%left Plus
%left Mult

%start <Ast.prog> prog

%%

prog: list(external_decl); list(typedef); expr; Eof
    { { external_decls = $1; typedefs = $2; expr = $3 } }

%inline external_decl:
  | External; Identifier; type_expr { $loc, $2, $3 }

%inline typedef:
  | Type; Identifier; option(typedef_poly_id); Equal;
       Lbrac; separated_nonempty_list(Comma, type_decl); Rbrac
    { { poly_param = string_of_ty_var $3; name = $2; labels = Array.of_list $6; loc = $loc } }

%inline type_decl:
  | Identifier; type_expr { $1, $2 }

expr:
  | Identifier { Var($loc, $1) }
  | Int { Int($loc, $1) }
  | bool { Bool($loc, $1) }
  | expr; binop; expr { Bop($loc, $2, $1, $3) }
  | If; expr; Then; expr; Else; expr; option(End) { If($loc, $2, $4, $6)}
  | decl; Equal; expr; expr { Let($loc, $1, $3, $4) }
  | Function; Lpar; separated_list(Comma, decl); Rpar; option(return_annot); expr; option(End)
    { Lambda($loc, $3, $5, $6) }
  | Function; Identifier; Lpar; separated_list(Comma, decl); Rpar; option(return_annot); expr; option(End); expr
    { Function ($loc, {name = $2; params = $4; return_annot = $6; body = $7; cont = $9}) }
  | expr; Lpar; separated_list(Comma, expr); Rpar { App($loc, $1, $3) }
  | Lbrac; separated_nonempty_list(Comma, record_item); Rbrac { Record ($loc, $2) }
  | expr; Dot; Identifier { Field ($loc, $1, $3) }
  | expr; MuchGreater; expr { Sequence ($loc, $1, $3) }

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
  | Arrow; type_list { $2 }

%inline typedef_poly_id:
  | Lpar; poly_id; Rpar { $2 }

%inline type_expr:
  | Colon; type_list; Arrow; type_list { [$2; $4] }
  | Colon; Lpar; separated_nonempty_list(Comma, type_func); Rpar; Arrow; type_list  { $3 @ [$6] }
  | Colon; type_list { [$2] }

%inline type_func:
  | type_list; Arrow; type_list { Ty_func [$1; $3] }
  | Lpar; separated_nonempty_list(Comma, type_list); Rpar; Arrow; type_list  { Ty_func ($2 @ [$5]) }
  | type_list { $1 }

%inline type_list:
  | build_type_list { Ty_list $1 }

build_type_list:
  | type_spec; Lpar; build_type_list; Rpar { $1 :: $3 }
  | type_spec { [$1] }

%inline type_spec:
  | Identifier { Ty_id $1 }
  | poly_id { $1 }

%inline poly_id:
  | Quote; Identifier { Ty_var $2 }
