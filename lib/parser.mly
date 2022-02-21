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
%token Arrow_right
%token Arrow_left
%token Dot
%token <string> Identifier
%token <int> Int
%token <string> String_lit
%token <string> Builtin_id
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
%token Lbrack
%token Rbrack
%token If
%token Then
%token Else
%token Eof
%token External
%token Fun
%token Fn
%token Type
%token Quote
%token Pipe_tail
%token Do
%token In
%token Mutable

%nonassoc Less
%left Plus
%left Mult
%left Arrow_right Pipe_tail Dot

%start <Ast.prog> prog

%%

prog: list(preface_item); block; Eof
    { { preface = $1; block = $2} }

%inline preface_item:
  | external_decl { $1 }
  | typedef { $1 }

%inline external_decl:
  | External; Identifier; type_expr { Ext_decl ($loc, $2, $3) }

%inline typedef:
  | typdef { Typedef ($loc, $1) }

%inline typdef:
  | Type; Identifier; option(typedef_poly_id); Equal;
       Lbrac; separated_nonempty_list(Comma, type_decl); Rbrac
    { Trecord { name = {name = $2; poly_param = string_of_ty_var $3}; labels = Array.of_list $6 } }
  | Type; Identifier; option(typedef_poly_id); Equal; type_list
    { Talias ({name = $2; poly_param = string_of_ty_var $3}, $5) }

/* Only used for records */
%inline type_decl:
  | boption(Mutable); Identifier; type_expr { $1, $2, $3 }

block:
  | list(stmt) { ($loc, $1) }

exprblock:
  | expr { $loc, [Expr ($sloc, $1)] }
  | Do; list(stmt); In; expr { $loc, $2 @ [Expr ($sloc, $4)] }

stmt:
  | decl; Equal; exprblock { Let($loc, $1, $3) }
  | Fun; Identifier; Lpar; separated_list(Comma, decl); Rpar; option(return_annot); Equal; exprblock
    { Function ($loc, {name = $2; params = $4; return_annot = $6; body = $8}) }
  | expr { Expr ($loc, $1) }

expr:
  | Identifier { Var($loc, $1) }
  | Int { Lit($loc, Int $1) }
  | bool { Lit($loc, Bool  $1) }
  | String_lit { Lit($loc, String $1) }
  | vector_lit { Lit($loc, Vector $1) }
  | Lpar; Rpar { Lit($loc, Unit) }
  | expr; binop; expr { Bop($loc, $2, $1, $3) }
  | If; expr; Then; block; Else; exprblock { If($loc, $2, $4, $6) }
  | Fn; Lpar; separated_list(Comma, decl); Rpar; option(return_annot); exprblock
    { Lambda($loc, $3, $5, $6) }
  | callable; Lpar; separated_list(Comma, expr); Rpar { App($loc, $1, $3) }
  | Lbrac; separated_nonempty_list(Comma, record_item); Rbrac { Record ($loc, $2) }
  | expr; Dot; Identifier; Arrow_left; expr { Field_set ($loc, $1, $3, $5) } /* Copying the first part makes checking for mutability easier */
  | expr; Dot; Identifier { Field ($loc, $1, $3) }
  | expr; Arrow_right; expr { Pipe_head ($loc, $1, $3) }
  | expr; Pipe_tail; expr { Pipe_tail ($loc, $1, $3) }

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

%inline callable:
  | expr { $1 }
  | Builtin_id { Var($loc, $1) }

vector_lit:
  | Lbrack; separated_list(Comma, expr); Rbrack { $2 }

%inline return_annot:
  | Arrow_right; type_list { $2 }

%inline typedef_poly_id:
  | Lpar; poly_id; Rpar { $2 }

%inline type_expr:
  | Colon; type_list; Arrow_right; type_list { [$2; $4] }
  | Colon; Lpar; separated_nonempty_list(Comma, type_func); Rpar; Arrow_right; type_list  { $3 @ [$6] }
  | Colon; type_list { [$2] }

%inline type_func:
  | type_list; Arrow_right; type_list { Ty_func [$1; $3] }
  | Lpar; separated_nonempty_list(Comma, type_list); Rpar; Arrow_right; type_list  { Ty_func ($2 @ [$5]) }
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
