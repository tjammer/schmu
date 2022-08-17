%{
    open Ast

    let string_of_ty_var = function
      | None -> None
      | Some (Ty_var s) -> Some s
      | _ -> failwith "Internal Error: Should have been a type var"

    let make_pairs bin arg args =
      let rec build = function
        | [ a ] -> bin arg a
        | a :: tl -> bin (build tl) a
        | [] -> failwith "unreachable"
      in
      build (List.rev args)

%}

%token Equal
%token Arrow_right
%token Arrow_righter
%token Dot
%token Do
%token <string> Lowercase_id
%token <string> Uppercase_id
%token <string> Kebab_id
%token <string> Name
%token <string> Constructor
%token <string> Accessor
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
%token Eof
%token Fun
%token Val
%token Quote
%token Match
%token Mutable
%token Wildcard
%token Open
%token Defrecord
%token Defalias
%token Defvariant
%token Defexternal
%token Setf

%start <Ast.prog> prog

%%

prog: prog = list(top_item); Eof { prog }

top_item:
  | stmt = stmt { Stmt stmt }
  | decl = external_decl { Ext_decl decl }
  | def = typedef { Typedef ($loc, def) }
  | open_ { Open ($loc, $1) }

%inline external_decl:
  | parenss(defexternal) { $1 }

%inline typedef:
  | parenss(defrecord) { $1 }
  | parenss(defalias) { $1 }
  | parenss(defvariant) { $1 }

%inline defexternal:
  | Defexternal; ident; sexp_type_expr; option(String_lit) { $loc, $2, $3, $4 }

%inline defrecord:
  | Defrecord; sexp_typename; maybe_bracs(nonempty_list(sexp_type_decl))
    { Trecord { name = $2; labels = Array.of_list $3 } }

%inline defalias:
  | Defalias; sexp_typename; sexp_type_list { Talias ($2, $3 ) }

%inline defvariant:
  | Defvariant; sexp_typename; atom_or_list(sexp_ctordef) { Tvariant { name = $2; ctors = $3 } }

let atom_or_list(x) :=
  | atom = x; { [atom] }
  | list = parenss(nonempty_list(x)); { list }

let atom_or_quoted_list(x) :=
  | atom = x; { [atom] }
  | Quote; list = parenss(nonempty_list(x)); { list }

let maybe_bracs(x) :=
  | Lpar; thing = x; Rpar; { thing }
  | Lbrac; thing = x; Rbrac; { thing }

let maybe_bracks(x) :=
  | Lpar; thing = x; Rpar; { thing }
  | Lbrack; thing = x; Rbrack; { thing }

%inline sexp_ctordef:
  | parenss(sexp_ctordef_item) { $1 }
  | sexp_ctor { { name = $1; typ_annot = None; index = None } }

%inline sexp_ctordef_item:
  | sexp_ctor; sexp_type_list { { name = $1; typ_annot = Some $2; index = None } }
  | sexp_ctor; Int { { name = $1; typ_annot = None; index = Some $2 } }

%inline sexp_typename:
  | ident { { name = snd $1; poly_param = None } }
  | Lpar; ident; poly_id; Rpar { { name = snd $2; poly_param = string_of_ty_var (Some $3) } }

%inline sexp_type_decl:
  | Name; sexp_type_expr { false, $1, $2 }
  | Name; Lpar; Mutable; sexp_type_expr; Rpar { true, $1, $4 }

%inline open_:
  | parenss(sexp_open) { $1 }

%inline sexp_open:
  | Open; ident { snd $2 }

block:
  | stmt = stmt { [stmt] }
  | Lpar; Do; stmts = nonempty_list(stmt); Rpar { stmts }

stmt:
  | parenss(sexp_let) { $1 }
  | parenss(sexp_fun) { $1 }
  | sexp_expr { Expr ($loc, $1) }

%inline sexp_let:
  | Val; sexp_decl; block { Let($loc, $2, $3) }

%inline sexp_decl:
  | ident { $loc, $1, None }
  | parenss(sexp_decl_typed) { $1 }

%inline sexp_decl_typed:
  | ident; sexp_type_expr { $loc, $1, Some $2 }

%inline sexp_fun:
  | Fun; ident; maybe_bracks(list(sexp_decl)); list(stmt)
    { Function ($loc, { name = $2; params = $3; return_annot = None; body = $4 }) }

sexp_expr:
  | ident { Var (fst $1, snd $1) }
  | maybe_bracs(nonempty_list(sexp_record_item)) { Record ($loc, $1) }
  | sexp_ctor_inst { $1 }
  | sexp_lit { $1 }
  | sexp_binop { $1 }
  | unop; sexp_expr { Unop ($loc, $1, $2) }
  | parenss(sexp_if) { $1 }
  | parenss(sexp_lambda) { $1 }
  | parenss(sexp_field_set) { $1 }
  | parenss(sexp_field_get) { $1 }
  | parenss(sexp_pipe_head) { $1 }
  | parenss(sexp_pipe_tail) { $1 }
  | parenss(sexp_call) { $1 }
  | sexp_module_expr { $1 }
  | parenss(sexp_match) { $1 }

%inline sexp_record_item:
  | Name; sexp_expr { $1, $2 }
  | Name { $1, Var ($loc, $1) }

%inline sexp_ctor_inst:
  | sexp_ctor { Ctor ($loc, $1, None) }
  | parenss(sexp_ctor_item) { $1 }

%inline sexp_ctor_item:
  | sexp_ctor; sexp_expr { Ctor ($loc, $1, Some $2) }

%inline sexp_lit:
  | Int { Lit($loc, Int $1) }
  | U8  { Lit($loc, U8 $1) }
  | bool { Lit($loc, Bool  $1) }
  | Float { Lit($loc, Float $1) }
  | I32 { Lit($loc, I32 $1) }
  | F32 { Lit($loc, F32 $1) }
  | String_lit { Lit($loc, String $1) }
  | sexp_vector_lit { Lit($loc, Vector $1) }
  | Lpar; Rpar { Lit($loc, Unit) }

%inline sexp_binop:
  | parenss(sexp_binop_items) { $1 }

%inline sexp_binop_items:
  | binop; sexp_expr; nonempty_list(sexp_expr)
    { make_pairs (fun a b -> Ast.Bop ($loc, $1, a, b)) $2 $3 }

%inline sexp_if:
  | If; sexp_expr; block; option(block) { If ($loc, $2, $3, $4) }

%inline sexp_lambda:
  | Fun; maybe_bracks(list(sexp_decl)) list(stmt)
    { Lambda ($loc, $2, $3) }

%inline sexp_field_set:
  | Setf; sexp_expr; Accessor; sexp_expr { Field_set ($loc, $2, $3, $4) }

%inline sexp_field_get:
  | Accessor; sexp_expr { Field ($loc, $2, $1) }

%inline sexp_pipe_head:
  | Arrow_right; sexp_expr; nonempty_list(sexp_expr)
    { make_pairs (fun a b -> Ast.Pipe_head ($loc, a, b)) $2 $3 }

%inline sexp_pipe_tail:
  | Arrow_righter; sexp_expr; nonempty_list(sexp_expr)
    { make_pairs (fun a b -> Ast.Pipe_tail ($loc, a, b)) $2 $3 }

%inline sexp_call:
  | sexp_expr { App ($loc, $1, []) }
  | sexp_expr; sexp_expr { App ($loc, $1, [$2]) }
  | sexp_expr; nonempty_list(sexp_expr) { App ($loc, $1, $2) }
  | Builtin_id; list(sexp_expr) { App ($loc, Var($loc, $1), $2) }

%inline sexp_module_expr:
  | ident; Div_i; block { Local_open ($loc, snd $1, $3) }

%inline sexp_match:
  | Match; atom_or_quoted_list(sexp_expr); nonempty_list(sexp_clause) { Match (($startpos, $endpos($2)), $2, $3) }

%inline sexp_clause:
  | sexp_pattern; block { $loc($1), $1, $2 }

%inline sexp_pattern:
  | sexp_pattern_item { $1 }
  | Quote; Lpar; tup = sexp_pattern_tuple; Rpar { tup }

%inline sexp_pattern_item:
  | sexp_ctor { Pctor ($1, None) }
  | parenss(ctor_pattern_item) { $1 }
  | ident { Pvar(fst $1, snd $1) }
  | Wildcard { Pwildcard $loc }

%inline ctor_pattern_item:
  | sexp_ctor; sexp_pattern { Pctor ($1, Some $2) }

%inline sexp_pattern_tuple:
  | sexp_pattern_item; nonempty_list(sexp_pattern_item) { Ptup ($loc, $1 :: $2) }

ident:
  | Lowercase_id { ($loc, $1) }
  | Kebab_id { ($loc, $1) }

sexp_ctor:
  | Constructor { $loc, $1 }

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

sexp_vector_lit:
  | Lbrack; list(sexp_expr); Rbrack { $2 }

%inline sexp_type_expr:
  | sexp_type_list { $1 }
  | parenss(sexp_type_func) { $1 }

%inline sexp_type_func:
  | Fun; nonempty_list(sexp_type_expr) { Ty_func $2 }

%inline sexp_type_list:
  | build_sexp_type_list { Ty_list $1 }

build_sexp_type_list:
  | Lpar; type_spec; build_sexp_type_list; Rpar { $2 :: $3 }
  | type_spec { [$1] }

type_spec:
  | ident { Ty_id (snd $1) }
  | poly_id { $1 }
  | Uppercase_id; Dot; type_spec { Ty_open_id ($loc, $3, $1) }

%inline poly_id:
  | Quote; Lowercase_id { Ty_var $2 }
