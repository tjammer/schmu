%{
    open Ast

    let string_of_ty_var = function
      | None -> None
      | Some (Ty_var s) -> Some s
      | _ -> failwith "Internal Error: Should have been a type var"

    let parse_elseifs loc cond then_ elseifs else_ =
      let rec aux = function
        | [ (loc, cond, blk) ] ->
            (loc, [ Ast.Expr (loc, Ast.If (loc, cond, blk, else_)) ])
        | (loc, cond, blk) :: tl ->
            (loc, [ Ast.Expr (loc, If (loc, cond, blk, aux tl)) ])
        | [] -> else_
      in
      Ast.If (loc, cond, then_, aux elseifs)

%}

%token Equal
%token Comma
%token Colon
%token Arrow_right
%token Arrow_left
%token Dot
%token <string> Identifier
%token <int> Int
%token <char> U8
%token <float> Float
%token <string> String_lit
%token <string> Builtin_id
%token True
%token False
%token Plus_i
%token Minus_i
%token Mult_i
%token Div_i
%token Plus_f
%token Minus_f
%token Mult_f
%token Div_f
%token Less_i
%token Less_f
%token Greater_i
%token Greater_f
%token Bin_equal_i
%token Bin_equal_f
%token Lpar
%token Rpar
%token Lbrac
%token Rbrac
%token Lbrack
%token Rbrack
%token If
%token Then
%token Elseif
%token Else
%token End
%token Eof
%token External
%token Fun
%token Type
%token Quote
%token Pipe_tail
%token Do
%token Mutable

%nonassoc Less_i Less_f Greater_i Greater_f
%left Plus_i Plus_f Minus_i Minus_f
%left Mult_i Mult_f Div_i Div_f
%left Bin_equal_i Bin_equal_f
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
  | list(stmt); /*loption(In; expr)*/ { ($loc, $1) }

exprblock:
  | expr { $loc, [Expr ($sloc, $1)] }
  | Do; list(stmt); End { $loc, $2 }

stmt:
  | decl; Equal; exprblock { Let($loc, $1, $3) }
  | Fun; Identifier; parens(decl); option(return_annot); block; End
    { Function ($loc, {name = $2; params = $3; return_annot = $4; body = $5}) }
  | expr { Expr ($loc, $1) }

expr:
  | Identifier { Var($loc, $1) }
  | lit { $1 }
  | expr; binop; expr { Bop($loc, $2, $1, $3) }
  | If; expr; Then; block; list(elif); Else; block; End { parse_elseifs $loc $2 $4 $5 $7 }
  | Fun; parens(decl); option(return_annot); block; End
    { Lambda($loc, $2, $3, $4) }
  | callable; parens(expr) { App($loc, $1, $2) }
  | Lbrac; separated_nonempty_list(Comma, record_item); Rbrac { Record ($loc, $2) }
  | expr; Dot; Identifier; Arrow_left; expr { Field_set ($loc, $1, $3, $5) } /* Copying the first part makes checking for mutability easier */
  | expr; Dot; Identifier { Field ($loc, $1, $3) }
  | expr; Arrow_right; expr { Pipe_head ($loc, $1, $3) }
  | expr; Pipe_tail; expr { Pipe_tail ($loc, $1, $3) }

%inline lit:
  | Int { Lit($loc, Int $1) }
  | U8  { Lit($loc, U8 $1) }
  | bool { Lit($loc, Bool  $1) }
  | Float { Lit($loc, Float $1) }
  | String_lit { Lit($loc, String $1) }
  | vector_lit { Lit($loc, Vector $1) }
  | Lpar; Rpar { Lit($loc, Unit) }

%inline elif:
  | Elseif; expr; Then; block { ($loc, $2, $4) }

%inline record_item:
  | Identifier; Equal; expr { $1, $3 }

let parens(x) :=
  | Lpar; lst = separated_list(Comma, x); Rpar; { lst }

bool:
  | True { true }
  | False { false }

%inline binop:
  | Plus_i  { Plus_i }
  | Minus_i { Minus_i }
  | Mult_i  { Mult_i }
  | Div_i   { Div_i }
  | Less_i  { Less_i }
  | Greater_i { Greater_i }
  | Bin_equal_i { Equal_i }
  | Plus_f  { Plus_f }
  | Minus_f { Minus_f }
  | Mult_f  { Mult_f }
  | Div_f   { Div_f }
  | Less_f  { Less_f }
  | Greater_f { Greater_f }
  | Bin_equal_f { Equal_f }

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
