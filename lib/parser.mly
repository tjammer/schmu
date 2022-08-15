%{
    open Ast

    let string_of_ty_var = function
      | None -> None
      | Some (Ty_var s) -> Some s
      | _ -> failwith "Internal Error: Should have been a type var"

    let parse_elseifs loc cond then_ elseifs else_ =
      let rec aux = function
        | [ (loc, cond, blk) ] ->
            Some [ Ast.Expr (loc, Ast.If (loc, cond, blk, else_)) ]
        | (loc, cond, blk) :: tl ->
            Some [ Ast.Expr (loc, If (loc, cond, blk, aux tl)) ]
        | [] -> else_
      in
      Ast.If (loc, cond, then_, aux elseifs)

%}

%token Equal
%token Comma
%token Colon
%token Bar
%token Arrow_right
%token Arrow_left
%token Dot
%token <string> Lowercase_id
%token <string> Uppercase_id
%token <string> Kebab_id
%token <string> Name
%token <string> Constructor
%token <int> Int
%token <char> U8
%token <float> Float
%token <int> I32
%token <float> F32
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
%token Bin_equal_f
%token And
%token Or
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
%token Begin
%token End
%token Eof
%token External
%token Fun
%token Val
%token Type
%token Quote
%token Pipe_head
%token Pipe_tail
%token Mutable
%token Match
%token With
%token Wildcard
%token Open
%token Defrecord
%token Defalias
%token Defvariant

%left And Or
%nonassoc Less_i Less_f Greater_i Greater_f
%left Plus_i Plus_f Minus_i Minus_f
%left Mult_i Mult_f Div_i Div_f
%left Equal Bin_equal_f
%left Pipe_head Pipe_tail Dot

%start <Ast.prog> prog

%%

prog: prog = list(top_item); Eof { prog }

top_item:
  | stmt = stmt { Stmt stmt }
  | decl = external_decl { Ext_decl decl }
  | def = typedef { Typedef ($loc, def) }
  | open_ { Open ($loc, $1) }

%inline external_decl:
  | External; ident; type_expr; option(external_cname) { $loc, $2, $3, $4 }

%inline external_cname:
  | Equal; String_lit { $2 }

%inline typedef:
  | parenss(defrecord) { $1 }
  | Type; typename; Equal; Lbrac; separated_nonempty_list(Comma, type_decl); Rbrac
    { Trecord { name = $2; labels = Array.of_list $5 } }
  | parenss(defalias) { $1 }
  | Type; typename; Equal; type_list
    { Talias ($2, $4) }
  | parenss(defvariant) { $1 }
  | Type; typename; Equal; separated_nonempty_list(Bar, ctordef)
    { Tvariant { name = $2; ctors = $4 } }

%inline defrecord:
  | Defrecord; sexp_typename; maybe_bracs(nonempty_list(sexp_type_decl))
    { Trecord { name = $2; labels = Array.of_list $3 } }

%inline defalias:
  | Defalias; sexp_typename; sexp_type_list { Talias ($2, $3 ) }

%inline defvariant:
  | Defvariant; sexp_typename; atom_or_list(parenss(sexp_ctordef)) { Tvariant { name = $2; ctors = $3 } }

let atom_or_list(x) :=
  | atom = x; { [atom] }
  | list = parenss(nonempty_list(x)); { list }

let maybe_bracs(x) :=
  | Lpar; thing = x; Rpar; { thing }
  | Lbrac; thing = x; Rbrac; { thing }

%inline sexp_ctordef:
  | sexp_ctor; sexp_type_list { { name = $1; typ_annot = Some $2; index = None } }
  | sexp_ctor; Int { { name = $1; typ_annot = None; index = Some $2 } }

%inline sexp_typename:
  | ident { { name = snd $1; poly_param = None } }
  | Lpar; ident; poly_id; Rpar { { name = snd $2; poly_param = string_of_ty_var (Some $3) } }

%inline sexp_type_decl:
  | Name; sexp_type_expr { false, $1, $2 }

%inline open_:
  | Open; Uppercase_id { $2 }

%inline ctordef:
  | ctor; option(ctyp); option(tag) { { name = $1; typ_annot = $2; index = $3 } }

%inline ctyp:
  | Lpar; type_func; Rpar { $2 }

%inline tag:
  | Colon; Int { $2 }

%inline typename:
  | Lowercase_id; option(typedef_poly_id) { { name = $1; poly_param = string_of_ty_var $2 } }

/* Only used for records */
%inline type_decl:
  | boption(Mutable); Lowercase_id; type_expr { $1, $2, $3 }

block:
  | expr { [Expr ($sloc, $1)] }
  | Begin; nonempty_list(stmt); End { $2 }

stmt:
  | Val; decl; Equal; block { Let($loc, $2, $4) }
  | Fun; ident; parensl(decl); option(return_annot); Equal; block
    { Function ($loc, {name = $2; params = $3; return_annot = $4; body = $6}) }
  | expr { Expr ($loc, $1) }

expr:
  | module_expr { $1 }
  | lit { $1 }
  | expr; binop; expr { Bop($loc, $2, $1, $3) }
  | unop; expr { Unop ($loc, $1, $2) }
  | If; expr; Then; block; list(elif); option(elseblk) { parse_elseifs $loc $2 $4 $5 $6 }
  | Fun; parensl(decl); Arrow_right; block
    { Lambda($loc, $2, $4) }
  | callable; parensl(expr) { App($loc, $1, $2) }
  | expr; Dot; Lowercase_id; Arrow_left; expr { Field_set ($loc, $1, $3, $5) } /* Copying the first part makes checking for mutability easier */
  | expr; Dot; Lowercase_id { Field ($loc, $1, $3) }
  | expr; Pipe_head; expr { Pipe_head ($loc, $1, $3) }
  | expr; Pipe_tail; expr { Pipe_tail ($loc, $1, $3) }
  | Match; separated_nonempty_list(Comma, expr); With; Begin; nonempty_list(clause); End { Match (($startpos, $endpos($5)), $2, $5) }
  | Uppercase_id; Dot; module_expr { Local_open ($loc, $1, [Expr ($sloc, $3)]) }
  | Uppercase_id; Dot; Lpar; nonempty_list(stmt); Rpar { Local_open ($loc, $1, $4) }

%inline module_expr:
  | Lowercase_id { Var($loc, $1) }
  | Lbrac; separated_nonempty_list(Comma, record_item); Rbrac { Record ($loc, $2) }
  | Lpar; expr; Rpar { $2 }
  | ctor; option(parenss(expr)) { Ctor ($loc, $1, $2) }

%inline lit:
  | Int { Lit($loc, Int $1) }
  | U8  { Lit($loc, U8 $1) }
  | bool { Lit($loc, Bool  $1) }
  | Float { Lit($loc, Float $1) }
  | I32 { Lit($loc, I32 $1) }
  | F32 { Lit($loc, F32 $1) }
  | String_lit { Lit($loc, String $1) }
  | vector_lit { Lit($loc, Vector $1) }
  | Lpar; Rpar { Lit($loc, Unit) }

%inline elseblk:
  | Else; block { $2 }

%inline elif:
  | Elseif; expr; Then; block { ($loc, $2, $4) }

%inline record_item:
  | Lowercase_id; Equal; expr { $1, $3 }
  | Lowercase_id { $1, Var($loc, $1) }

%inline clause:
  | pattern; Arrow_right; block { $loc($1), $1, $3 }

%inline pattern:
  | pattern_item { $1 }
  | pattern_tuple { $1 }

%inline pattern_item:
  | ctor; option(parenss(pattern)) { Pctor($1, $2) }
  | Lowercase_id { Pvar($loc, $1) }
  | Wildcard { Pwildcard $loc }

%inline pattern_tuple:
  | pattern_item; Comma; separated_nonempty_list(Comma, pattern_item) { Ptup($loc, $1 :: $3) }

ident:
  | Lowercase_id { ($loc, $1) }
  | Kebab_id { ($loc, $1) }

ctor:
  | Uppercase_id { $loc, $1 }

sexp_ctor:
  | Constructor { $loc, $1 }

let parensl(x) :=
  | Lpar; lst = separated_list(Comma, x); Rpar; { lst }

let parenss(x) :=
  | Lpar; item = x; Rpar; { item }

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
  | Equal { Equal_i }
  | Plus_f  { Plus_f }
  | Minus_f { Minus_f }
  | Mult_f  { Mult_f }
  | Div_f   { Div_f }
  | Less_f  { Less_f }
  | Greater_f { Greater_f }
  | Bin_equal_f { Equal_f }
  | And     { And }
  | Or      { Or }

%inline unop:
  | Minus_i { Uminus_i }
  | Minus_f { Uminus_f }

%inline decl:
  | ident; option(type_expr) {$loc, $1, $2 }

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
  | Colon; type_list; Arrow_right; type_list { Ty_func [ $2; $4] }
  | Colon; Lpar; separated_nonempty_list(Comma, type_func); Rpar; Arrow_right; type_list  { Ty_func ($3 @ [$6]) }
  | Colon; type_list { $2 }

%inline sexp_type_expr:
  | sexp_type_list { $1 }
  | parenss(sexp_type_func) { $1 }

%inline sexp_type_func:
  | Fun; nonempty_list(sexp_type_expr) { Ty_func $2 }

%inline sexp_type_list:
  | build_sexp_type_list { Ty_list $1 }

%inline type_func:
  | type_list; Arrow_right; type_list { Ty_func [$1; $3] }
  | Lpar; separated_nonempty_list(Comma, type_list); Rpar; Arrow_right; type_list  { Ty_func ($2 @ [$5]) }
  | type_list { $1 }

%inline type_list:
  | build_type_list { Ty_list $1 }

build_type_list:
  | type_spec; Lpar; build_type_list; Rpar { $1 :: $3 }
  | type_spec { [$1] }

build_sexp_type_list:
  | Lpar; type_spec; build_sexp_type_list; Rpar { $2 :: $3 }
  | type_spec { [$1] }

type_spec:
  | Lowercase_id { Ty_id $1 }
  | poly_id { $1 }
  | Uppercase_id; Dot; type_spec { Ty_open_id ($loc, $3, $1) }

%inline poly_id:
  | Quote; Lowercase_id { Ty_var $2 }
