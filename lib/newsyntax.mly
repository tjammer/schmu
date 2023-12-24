%{
    open Ast
%}

%start <Ast.prog> prog

%%

prog:
  | s = parens(signature); prog = list(top_item); Eof { s, prog }
  | prog = list(top_item); Eof { [], prog }

top_item:
/* Split top-level items into toplvl_items for files and module_items for
   module expressions. That's useful to allow module aliases. Otherwise a module
   alias would be parsed as a module with an ident expression */
  | toplvl_item { $1 }
  | module_item { $1 }

%inline toplvl_item:
  | stmt = toplvl_stmt { Stmt stmt }

%inline module_item:
  | stmt = module_stmt { Stmt stmt }
  | decl = external_decl { Ext_decl decl }
  | def = typedef { Typedef ($loc, def) }
  | modul = parens(modul) { modul }
  | module_type = parens(module_type) { module_type }

%inline first_module_item:
  | module_item { $1 }
  | Lpar; Rpar { Stmt (Expr ($loc, (Lit ($loc, Unit)))) }

signature: Signature; l = nonempty_list(sig_item) { l }

%inline sig_item:
  | def = sigtypedef { Stypedef ($loc, def) }
  | v = parens(sigvalue) { Svalue (fst v, snd v) }

%inline sigvalue:
  | Def; id = ident; t = sexp_type_expr { $loc, (id, t) }

%inline external_decl:
  | parens(defexternal) { $1 }

%inline sigtypedef:
  | parens(defrecord) { $1 }
  | parens(defalias) { $1 }
  | parens(defvariant) { $1 }
  | parens(defabstract) { $1 }

%inline typedef:
  | parens(defrecord) { $1 }
  | parens(defalias) { $1 }
  | parens(defvariant) { $1 }

%inline defexternal:
  | Defexternal; ident; sexp_type_expr; option(String_lit) { $loc, $2, $3, $4 }

modul:
  | Module; id = module_decl { let loc, alias, _ = id in Module_alias (id, Amodule (loc, Path.Pid alias)) }
  | Module; id = module_decl; alias = aliased_module /* Use location of alias */
    { let _, id, annot = id in Module_alias (($loc(alias), id, annot), alias) }
  | Module; id = module_decl; hd = first_module_item; m = list(top_item) { Module (id, [], hd :: m) }
  | Module; id = module_decl; s = parens(signature); m = list(top_item) { Module (id, s, m) }
  | Functor; id = module_decl; p = parens(functor_params); hd = first_module_item; m = list(top_item)
    { Functor (id, p, [], hd :: m) }
  | Functor; id = module_decl; p = parens(functor_params); s = parens(signature); m = list(top_item)
    { Functor (id, p, s, m) }

%inline module_type:
  | Module_type; id = ident; l = nonempty_list(sig_item) { Module_type (id, l) }

%inline module_decl:
  | id = ident { fst id, snd id, None }
  | decl = bracks(module_annot) { decl }

%inline functor_params:
  | nonempty_list(bracks(functor_param)) { $1 }

%inline functor_param:
  | id = ident; param = path { $loc, snd id, snd param }

%inline module_annot:
  | id = ident; annot = path { fst id, snd id, Some (snd annot) }

%inline path:
  | id = ident { $loc, Path.Pid (snd id) }
  | id = ident; Div_i; lst = separated_nonempty_list(Div_i, ident)
    { $loc, flatten_import (id :: lst) }

%inline aliased_module:
/* Partial functor applications are not supported */
  | m = path { Amodule m }
  | parens(functor_app) { $1 }

%inline functor_app:
  | f = path; args = nonempty_list(path) { Afunctor_app (f, args) }

%inline defrecord:
  | Type; sexp_typename; bracs(nonempty_list(sexp_type_decl))
    { Trecord { name = $2; labels = Array.of_list $3 } }

%inline defalias:
  | Type; sexp_typename; sexp_type_list { Talias ($2, $3 ) }

%inline defvariant:
  | Type; sexp_typename; atom_or_list(sexp_ctordef) { Tvariant { name = $2; ctors = $3 } }

%inline defabstract:
  | Type; sexp_typename { Tabstract $2 }

let atom_or_list(x) :=
  | atom = x; { [atom] }
  | list = parens(nonempty_list(x)); { list }

let bracs(x) :=
  | Lbrac; thing = x; Rbrac; { thing }

let bracks(x) :=
  | Lbrack; thing = x; Rbrack; { thing }

%inline sexp_ctordef:
  | parens(sexp_ctordef_item) { $1 }
  | sexp_ctor { { name = $1; typ_annot = None; index = None } }

sexp_ctordef_item:
  | sexp_ctor; sexp_type_list { { name = $1; typ_annot = Some $2; index = None } }
  | sexp_ctor; Int { { name = $1; typ_annot = None; index = Some $2 } }

sexp_typename:
  | ident { { name = snd $1; poly_param = [] } }
  | Lpar; ident; polys = nonempty_list(poly_id); Rpar
    { { name = snd $2; poly_param = List.map path_of_ty_var polys } }

sexp_type_decl:
  | name = Keyword; t = sexp_type_expr { false, name, t }
  | name = Mut_keyword; t = sexp_type_expr; { true, name, t }

%inline import_:
  | parens(sexp_import) { $1 }

%inline sexp_import:
  | Import; mname = path { snd mname }

stmt:
 | toplvl_stmt { $1 }
 | module_stmt { $1 }

%inline toplvl_stmt:
  | sexp_expr { Expr ($loc, $1) }

%inline module_stmt:
  | parens(sexp_let) { $1 }
  | parens(sexp_fun) { Function (fst $1, snd $1) }
  | parens(sexp_rec) { $1}
  | import_ { Import ($loc, $1) }

%inline sexp_let:
  | Def; decl = sexp_decl; pexpr = passed_expr
    { let decl, pexpr = move_excl_to_right (decl, pexpr) in Let($loc, decl, pexpr ) }
  /* Allow toplevel defs to alias builtins (to give them a better name) */
  | Def; sexp_decl; pexpr = Builtin_id { Let($loc, $2, {pattr = Dnorm; pexpr = Var($loc(pexpr), pexpr)}) }

sexp_decl:
  | bracks(sexp_decl_typed) { $1 }
  | pattern = sexp_pattern { {loc = $loc; pattern; annot = None} }

sexp_decl_typed:
  | pattern = sexp_pattern; annot = sexp_type_expr
    { { loc = $loc; pattern; annot = Some annot } }

%inline decl_attr:
  | Ampersand { Dmut } | Exclamation { Dmove }

%inline sexp_fun:
  | Defn; name = ident; attr = list(attr); option(String_lit);
      params = parens(list(sexp_decl)); body = list(stmt)
    { ($loc, { name; params; return_annot = None; body; attr }) }

%inline attr:
  | kw = Keyword { Fa_single ($loc, kw) }
  | kw = Keyword; lst = nonempty_list(ident) { Fa_param (($loc(kw), kw), lst) }

%inline sexp_rec:
  | Rec; fst = parens(sexp_fun); tl = nonempty_list(parens(sexp_fun)) { Rec ($loc, fst :: tl) }

sexp_expr:
  | sexp_ctor_inst { $1 }
  | bracs(nonempty_list(sexp_record_item)) { Record ($loc, $1) }
  | exprs = bracs(nonempty_list(sexp_expr)) { Tuple ($loc, exprs) }
  | upd = bracs(record_update) { upd }
  | sexp_lit { $1 }
  | callable = callable_expr { callable }
  | unop; sexp_expr { Unop ($loc, $1, $2) }
  | parens(sexp_field_set) { $1 }
  | fmt = parens(fmt_str) { fmt }

callable_expr:
  | ident { Var (fst $1, snd $1) }
  | e = sexp_expr; f = Accessor {Field ($loc, e, f)}
  | e = sexp_expr; Ldotbrack; i = sexp_expr; Rbrack
    {App ($loc, Var ($loc, "__array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}
  | e = sexp_expr; Ldotparen; i = sexp_expr; Rpar
    {App ($loc, Var ($loc, "__fixed_array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}
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
  | Let; lets = parens(nonempty_list(parens(lets_let))); block = nonempty_list(stmt)
    { make_lets lets block }

%inline lets_let:
  | decl = sexp_decl; pexpr = passed_expr
    { let decl, pexpr = move_excl_to_right (decl, pexpr) in $loc, decl, pexpr }

%inline passed_expr:
  | attr = option(decl_attr); pexpr = sexp_expr { {pattr = pass_attr_of_opt attr; pexpr} }

%inline sexp_record_item:
  | Keyword; sexp_expr { $1, $2 }
  | Keyword { $1, Var ($loc, $1) }

%inline record_update:
  | At; record = sexp_expr; items = nonempty_list(sexp_record_item)
    { Record_update ($loc, record, items) }

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
  | array_lit { Lit($loc, Array $1) }
  | Lpar; Rpar { Lit($loc, Unit) }
  | fixed_array_lit { Lit($loc, $1) }

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
  | Fn; attr = list(attr); params = parens(list(sexp_decl)); body = list(stmt)
    { Lambda ($loc, params, attr, body) }

%inline sexp_field_set:
  | Set; Ampersand; var = sexp_expr; Exclamation; value = sexp_expr
    { Set ($loc, ($loc(var), var), value) }

%inline sexp_field_get:
  | Accessor; sexp_expr { Field ($loc, $2, $1) }

%inline sexp_pipe_head:
  | Arrow_right; call_arg; nonempty_list(pipeable)
    { make_pairs (fun a b -> Ast.Pipe_head ($loc, a, b)) $2 $3 $loc }

%inline sexp_pipe_tail:
  | Arrow_righter; call_arg; nonempty_list(pipeable)
    { make_pairs (fun a b -> Ast.Pipe_tail ($loc, a, b)) $2 $3 $loc }

pipeable:
  | expr = sexp_expr { Pip_expr expr }
  | Fmt_str { Pip_expr (Fmt ($loc, [])) }
  | f = parens(Accessor) { Pip_field f }

sexp_call:
  | callable_expr { App ($loc, $1, []) }
  | callable_expr; call_arg { App ($loc, $1, [$2]) }
  | callable_expr; a1 = call_arg; args = nonempty_list(call_arg) { App ($loc, $1, a1 :: args) }
  | op = binop; exprs = nonempty_list(sexp_expr) { Bop ($loc, op, exprs) }
  | Builtin_id; list(call_arg) { App ($loc, Var($loc, $1), $2) }

call_arg:
  | amut = option(decl_attr); aexpr = sexp_expr { {apass = pass_attr_of_opt amut; aexpr; aloc = $loc} }

%inline do_block:
  | Do; stmts = nonempty_list(stmt) { Do_block stmts }

%inline sexp_module_expr:
  | ident; Div_i; sexp_expr { Local_import ($loc, snd $1, $3) }

%inline sexp_match:
  | Match; amut = option(decl_attr); expr = sexp_expr; clauses = nonempty_list(parens(sexp_clause))
    { Match (($startpos, $endpos(expr)), pass_attr_of_opt amut, expr, clauses) }

%inline sexp_clause:
  | sexp_pattern; sexp_expr { $loc($1), $1, $2 }

let with_loc(x) :=
  | item = x; { $loc, item }

sexp_pattern:
  | sexp_ctor { Pctor ($1, None) }
  | parens(ctor_pattern_item) { $1 }
  | ident; %prec below_Ampersand { Pvar ((fst $1, snd $1), Dnorm) }
  | ident; Ampersand { Pvar ((fst $1, snd $1), Dmut) }
  | ident; Exclamation { Pvar ((fst $1, snd $1), Dmove) }
  | Wildcard; %prec below_Ampersand { Pwildcard ($loc, Dnorm) }
  | Wildcard; Exclamation { Pwildcard ($loc, Dmove) }
  | Wildcard; Ampersand { Pwildcard ($loc, Dmut) }
  | items = bracs(nonempty_list(record_item_pattern)); %prec below_Ampersand { Precord ($loc, items, Dnorm) }
  | items = bracs(nonempty_list(record_item_pattern)); Exclamation { Precord ($loc, items, Dmove) }
  | i = Int { Plit_int ($loc, i) }
  | c = U8 {Plit_char ($loc, c)}
  | tup = bracs(sexp_pattern_tuple); %prec below_Ampersand { Ptup (fst tup, snd tup, Dnorm) }
  | tup = bracs(sexp_pattern_tuple); Exclamation { Ptup (fst tup, snd tup, Dmove) }
  | parens(or_pattern) { $1 }

%inline or_pattern:
  | Or; head = sexp_pattern; tail = nonempty_list(sexp_pattern)
    { Por ($loc, (head :: tail)) }

%inline record_item_pattern:
  | attr = Keyword; p = option(sexp_pattern) { ($loc(attr), attr), p }

ctor_pattern_item:
  | sexp_ctor; sexp_pattern { Pctor ($1, Some $2) }

%inline sexp_pattern_tuple:
  | with_loc(sexp_pattern); list(with_loc(sexp_pattern))
    { $loc, $1 :: $2 }

%inline fmt_str:
  | Fmt_str; lst = list(sexp_expr) { Fmt ($loc, lst) }

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
  | Less_eq_i  { Less_eq_i }
  | Greater_eq_i { Greater_eq_i }
  | Equal { Equal_i }
  | Plus_f  { Plus_f }
  | Minus_f { Minus_f }
  | Mult_f  { Mult_f }
  | Div_f   { Div_f }
  | Less_f  { Less_f }
  | Greater_f { Greater_f }
  | Less_eq_f  { Less_eq_f }
  | Greater_eq_f { Greater_eq_f }
  | Bin_equal_f { Equal_f }
  | And     { And }
  | Or      { Or }

%inline unop:
  | Minus_i { Uminus_i }
  | Minus_f { Uminus_f }

array_lit:
  | Lbrack; list(sexp_expr); Rbrack { $2 }

fixed_array_lit:
  | Hashtag_brack; items = nonempty_list(sexp_expr); Rbrack { Fixed_array items }
  | num = Hashnum_brack; item = sexp_expr; Rbrack { Fixed_array_num (num, item) }

%inline sexp_type_expr:
  | sexp_type_list { $1 }
  | parens(sexp_type_func) { $1 }

%inline sexp_type_func:
  | Fun; nonempty_list(sexp_fun_param) { Ty_func $2 }

sexp_fun_param:
  | spec = sexp_type_expr; attr = option(decl_attr) { spec, pass_attr_of_opt attr }

sexp_type_list:
  | Lpar; hd = type_spec; tl = nonempty_list(sexp_type_list); Rpar { Ty_list (hd :: tl) }
  | type_spec { $1 }

type_spec:
  | ident { Ty_id (snd $1) }
  | id = Sized_ident { Ty_id id }
  | id = Unknown_sized_ident { Ty_id id }
  | poly_id { $1 }
  | fst = ident; Div_i; lst = separated_nonempty_list(Div_i, ident)
    { Ty_import_id ($loc, flatten_import (fst :: lst) ) }
  | Lbrac; hd = type_spec; tl = nonempty_list(type_spec); Rbrac { Ty_tuple (hd :: tl)}

%inline poly_id:
  | Quote; Lowercase_id { Ty_var $2 }
