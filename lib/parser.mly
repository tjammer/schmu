%{
    open Ast

    let string_of_ty_var = function
      | Ty_var s -> s
      | _ -> failwith "Internal Error: Should have been a type var"

    let parse_cond loc fst then_ conds =
      let rec aux = function
        | [ (_, _, blk) ] -> blk
        | (loc, cond, blk) :: tl ->
            Some (If (loc, cond, Option.get blk, aux tl))
        | [] -> failwith "Menhir, this list should be nonempty"
      in
      Ast.If (loc, fst, then_, aux conds)

    let make_pairs bin arg args =
      let rec build = function
        | [ a ] -> bin arg a
        | a :: tl -> bin (build tl) a
        | [] -> failwith "unreachable"
      in
      build (List.rev args)

    let make_lets lets cont =
      let rec build = function
        | [ loc, name, expr ] -> Let_e (loc, name, expr, Do_block cont)
        | (loc, name, expr) :: tl -> Let_e (loc, name, expr, build tl)
        | [] -> failwith "unreachable"
      in
      build lets

%}

%token Equal
%token Arrow_right
%token Arrow_righter
%token Do
%token <string> Lowercase_id
%token <string> Kebab_id
%token <string> Keyword
%token <string> Constructor
%token <string> Accessor
%token <string> At_id
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
%token Else
%token Cond
%token Eof
%token Fun
%token Val
%token Let
%token Quote
%token Match
%token Mutable
%token Wildcard
%token Open
%token Type
%token Defexternal
%token Setf
%token Fmt_str

%start <Ast.prog> prog

%%

prog: prog = list(top_item); Eof { prog }

top_item:
  | stmt = stmt { Stmt stmt }
  | decl = external_decl { Ext_decl decl }
  | def = typedef { Typedef ($loc, def) }
  | open_ { Open ($loc, $1) }

%inline external_decl:
  | parens(defexternal) { $1 }

%inline typedef:
  | parens(defrecord) { $1 }
  | parens(defalias) { $1 }
  | parens(defvariant) { $1 }

%inline defexternal:
  | Defexternal; ident; sexp_type_expr; option(String_lit) { $loc, $2, $3, $4 }

%inline defrecord:
  | Type; sexp_typename; bracs(nonempty_list(sexp_type_decl))
    { Trecord { name = $2; labels = Array.of_list $3 } }

%inline defalias:
  | Type; sexp_typename; sexp_type_list { Talias ($2, $3 ) }

%inline defvariant:
  | Type; sexp_typename; atom_or_list(sexp_ctordef) { Tvariant { name = $2; ctors = $3 } }

let atom_or_list(x) :=
  | atom = x; { [atom] }
  | list = parens(nonempty_list(x)); { list }

let atom_or_tup_pattern(x) :=
  | atom = x; { [atom] }
  | Quote; list = bracs(nonempty_list(x)); { list }

let bracs(x) :=
  | Lbrac; thing = x; Rbrac; { thing }

let maybe_bracks(x) :=
  | Lpar; thing = x; Rpar; { thing }
  | Lbrack; thing = x; Rbrack; { thing }

let bracks(x) :=
  | Lbrack; thing = x; Rbrack; { thing }

%inline sexp_ctordef:
  | parens(sexp_ctordef_item) { $1 }
  | sexp_ctor { { name = $1; typ_annot = None; index = None } }

%inline sexp_ctordef_item:
  | sexp_ctor; sexp_type_list { { name = $1; typ_annot = Some $2; index = None } }
  | sexp_ctor; Int { { name = $1; typ_annot = None; index = Some $2 } }

%inline sexp_typename:
  | ident { { name = snd $1; poly_param = [] } }
  | Lpar; ident; polys = nonempty_list(poly_id); Rpar { { name = snd $2; poly_param = List.map string_of_ty_var polys } }

%inline sexp_type_decl:
  | Keyword; sexp_type_expr { false, $1, $2 }
  | Keyword; Lpar; Mutable; sexp_type_expr; Rpar { true, $1, $4 }

%inline open_:
  | parens(sexp_open) { $1 }

%inline sexp_open:
  | Open; ident { snd $2 }

stmt:
  | parens(sexp_let) { $1 }
  | parens(sexp_fun) { $1 }
  | sexp_expr { Expr ($loc, $1) }

%inline sexp_let:
  | Val; sexp_decl; sexp_expr { Let($loc, $2, $3) }

%inline sexp_decl:
  | ident { $loc, $1, None }
  | parens(sexp_decl_typed) { $1 }

%inline sexp_decl_typed:
  | ident; sexp_type_expr { $loc, $1, Some $2 }

%inline sexp_fun:
  | Fun; name = ident; attr = option(attr); option(String_lit); params = maybe_bracks(list(sexp_decl)); body = list(stmt)
    { Function ($loc, { name; params; return_annot = None; body; attr }) }

%inline attr:
  | kw = Keyword { $loc, kw }

sexp_expr:
  | sexp_ctor_inst { $1 }
  | bracs(nonempty_list(sexp_record_item)) { Record ($loc, $1) }
  | exprs = bracs(nonempty_list(sexp_expr)) { Tuple ($loc, exprs) }
  | upd = bracs(record_update) { upd }
  | sexp_lit { $1 }
  | unop; sexp_expr { Unop ($loc, $1, $2) }
  | callable = callable_expr { callable }
  | parens(sexp_field_set) { $1 }
  | fmt = parens(fmt_str) { fmt }

%inline callable_expr:
  | ident { Var (fst $1, snd $1) }
  | parens(lets) { $1 }
  | parens(sexp_if) { $1 }
  | parens(sexp_lambda) { $1 }
  | parens(sexp_field_get) { $1 }
  | parens(sexp_pipe_head) { $1 }
  | parens(sexp_pipe_tail) { $1 }
  | parens(sexp_call) { $1 }
  | parens(do_block) { $1 }
  | sexp_module_expr { $1 }
  | parens(sexp_match) { $1 }

%inline lets:
  | Let; lets = maybe_bracks(nonempty_list(lets_let)); block = nonempty_list(stmt)
    { make_lets lets block }

%inline lets_let:
  | decl = sexp_decl; expr = sexp_expr { $loc, decl, expr }

%inline sexp_record_item:
  | Keyword; sexp_expr { $1, $2 }
  | Keyword { $1, Var ($loc, $1) }

%inline record_update:
  | record = At_id; items = nonempty_list(sexp_record_item) { Record_update ($loc, ($loc(record), record), items) }

%inline sexp_ctor_inst:
  | sexp_ctor { Ctor ($loc, $1, None) }
  | parens(sexp_ctor_item) { $1 }

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

%inline sexp_if:
  | If; sexp_expr; sexp_expr; option(sexp_expr) { If ($loc, $2, $3, $4) }
  | Cond; cond = parens(cond_item) conds = sexp_cond
    { let loc, fst, then_ = cond in
      parse_cond loc fst (Option.get then_) conds }

%inline cond_item:
  | cond = sexp_expr; expr = sexp_expr { ($loc, cond, Some expr) }

%inline cond_else:
  | Else; e = sexp_expr { e }

sexp_cond:
  | cond = parens(cond_item); tl = sexp_cond { cond :: tl }
  | else_ = option(parens(cond_else)) { [$loc, Lit($loc, Unit), else_] }

%inline sexp_lambda:
  | Fun; params = maybe_bracks(list(sexp_decl)); body = list(stmt)
    { Lambda ($loc, params, body) }

%inline sexp_field_set:
  | Setf; access = parens(sexp_set_access); sexp_expr
    { Field_set ($loc, snd access, fst access, $3) }

%inline sexp_set_access:
  | acc = Accessor; exp = sexp_expr { acc, exp }

%inline sexp_field_get:
  | Accessor; sexp_expr { Field ($loc, $2, $1) }

%inline sexp_pipe_head:
  | Arrow_right; sexp_expr; nonempty_list(pipeable)
    { make_pairs (fun a b -> Ast.Pipe_head ($loc, a, b)) $2 $3 }

%inline sexp_pipe_tail:
  | Arrow_righter; sexp_expr; nonempty_list(pipeable)
    { make_pairs (fun a b -> Ast.Pipe_tail ($loc, a, b)) $2 $3 }

pipeable:
  | expr = sexp_expr { Pip_expr expr }
  | f = Accessor { Pip_field f }

%inline sexp_call:
  | callable_expr { App ($loc, $1, []) }
  | callable_expr; sexp_expr { App ($loc, $1, [$2]) }
  | callable_expr; a1 = sexp_expr; args = nonempty_list(sexp_expr) { App ($loc, $1, a1 :: args) }
  | op = binop; exprs = nonempty_list(sexp_expr) { Bop ($loc, op, exprs) }
  | Builtin_id; list(sexp_expr) { App ($loc, Var($loc, $1), $2) }

%inline do_block:
  | Do; stmts = nonempty_list(stmt) { Do_block stmts }

%inline sexp_module_expr:
  | ident; Div_i; sexp_expr { Local_open ($loc, snd $1, $3) }

%inline sexp_match:
  | Match; expr = sexp_expr; nonempty_list(parens(sexp_clause))
    { Match (($startpos, $endpos(expr)), expr, $3) }

%inline sexp_clause:
  | sexp_pattern; sexp_expr { $loc($1), $1, $2 }

let with_loc(x) :=
  | item = x; { $loc, item }

%inline sexp_pattern:
  | sexp_ctor { Pctor ($1, None) }
  | parens(ctor_pattern_item) { $1 }
  | ident { Pvar(fst $1, snd $1) }
  | Wildcard { Pwildcard $loc }
  | items = bracs(nonempty_list(record_item_pattern)) { Precord ($loc, items) }
  | i = Int { Plit_int ($loc, i) }
  | tup = bracs(sexp_pattern_tuple) { tup }


%inline record_item_pattern:
  | attr = attr; p = option(sexp_pattern) { fst attr, snd attr, p }

%inline ctor_pattern_item:
  | sexp_ctor; sexp_pattern { Pctor ($1, Some $2) }

%inline sexp_pattern_tuple:
  | with_loc(sexp_pattern); nonempty_list(with_loc(sexp_pattern))
    { Ptup ($loc, $1 :: $2) }

%inline fmt_str:
  | Fmt_str; lst = nonempty_list(sexp_expr) { Fmt ($loc, lst) }

ident:
  | Lowercase_id { ($loc, $1) }
  | Kebab_id { ($loc, $1) }

sexp_ctor:
  | Constructor { $loc, $1 }

let parens(x) :=
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
  | parens(sexp_type_func) { $1 }

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
  | ident; Div_i; type_spec { Ty_open_id ($loc, $3, snd $1) }

%inline poly_id:
  | Quote; Lowercase_id { Ty_var $2 }
