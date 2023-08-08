%{
    open Ast

    let path_of_ty_var = function
      | Ty_var s -> s
      | _ -> failwith "Internal Error: Should have been a type var"

    let rec flatten_open  = function
      | [] -> failwith "Internal Error: nonempty"
      | [ last ] -> Path.Pid (snd last)
      | hd :: tl -> Path.Pmod (snd hd, flatten_open tl)

    let parse_cond loc fst then_ conds =
      let rec aux = function
        | [ (_, _, blk) ] -> blk
        | (loc, cond, blk) :: tl ->
            Some (If (loc, cond, Option.get blk, aux tl))
        | [] -> failwith "Menhir, this list should be nonempty"
      in
      Ast.If (loc, fst, then_, aux conds)

    let make_pairs bin arg args aloc =
      let rec build = function
        | [ a ] -> bin arg a
        | a :: tl -> bin {(*TODO allow mutating *) apass = Dnorm; aexpr = (build tl); aloc} a
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

    let pass_attr_of_opt = function
      | Some (Ast.Dmut | Dset) -> Ast.Dmut
      | Some Dmove -> Dmove
      | Some Dnorm -> (* Won't happen but w/e *) Dnorm
      | None -> Dnorm

    let make_path head l =
      let p =
        match List.rev l with
        | hd :: tl ->
            List.fold_right (fun (_, id) path -> Path.Pmod (id, path)) tl (Pid (snd hd))
        | [] -> failwith "unreachable"
      in
      Path.Pmod (snd head, p)

%}

%token Equal
%token Arrow_right
%token Arrow_righter
%token Do
%token <string> Lowercase_id
%token <string> Kebab_id
%token <string> Keyword
%token <string> Mut_keyword
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
%token Less_eq_i
%token Less_eq_f
%token Greater_eq_i
%token Greater_eq_f
%token Bin_equal_f
%token And
%token Or
%token Lpar
%token Rpar
%token Lbrac
%token Rbrac
%token Ldotbrack
%token Lbrack
%token Rbrack
%token Ampersand
%token Exclamation
%token At
%token If
%token Else
%token Cond
%token Eof
%token Def
%token Defn
%token Fn
%token Fun
%token Let
%token Quote
%token Match
%token Wildcard
%token Open
%token Type
%token Defexternal
%token Signature
%token Module
%token Set
%token Fmt_str
%token Rec

%nonassoc below_Ampersand
%left Ampersand

%nonassoc Minus_i Minus_f
%left Accessor Ldotbrack
%left Div_i

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
  | Module; id = ident { Module (id, [], []) } /* empty module */
  | Module; id = ident; hd = module_item; m = list(top_item) { Module (id, [], hd :: m) }
  | Module; id = ident; s = parens(signature); m = list(top_item) { Module (id, s, m) }
  | Module; id = ident; mname = path /* Use location of path */
    { Module_alias ((fst mname, snd id), snd mname) }

%inline path:
  | id = ident { $loc, Path.Pid (snd id) }
  | id = ident; Div_i; l = separated_nonempty_list(Div_i, ident)
    { $loc, make_path id l }

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
  | Lpar; ident; polys = nonempty_list(poly_id); Rpar
    { { name = snd $2; poly_param = List.map path_of_ty_var polys } }

%inline sexp_type_decl:
  | name = Keyword; t = sexp_type_expr { false, name, t }
  | name = Mut_keyword; t = sexp_type_expr; { true, name, t }

%inline open_:
  | parens(sexp_open) { $1 }

%inline sexp_open:
  | Open; ident { snd $2 }

stmt:
 | toplvl_stmt { $1 }
 | module_stmt { $1 }

%inline toplvl_stmt:
  | sexp_expr { Expr ($loc, $1) }

%inline module_stmt:
  | parens(sexp_let) { $1 }
  | parens(sexp_fun) { Function (fst $1, snd $1) }
  | parens(sexp_rec) { $1}
  | open_ { Open ($loc, $1) }

%inline sexp_let:
  | Def; sexp_decl; pexpr = passed_expr { Let($loc, $2, pexpr ) }

sexp_decl:
  | parens(sexp_decl_typed) { $1 }
  | pattern = sexp_pattern; Ampersand
    { {loc = $loc; pattern; dattr = Dmut; annot = None} }
  | pattern = sexp_pattern; %prec below_Ampersand
    { {loc = $loc; pattern; dattr = Dnorm; annot = None} }

param:
  | parens(sexp_decl_typed) { $1 }
  | pattern = sexp_pattern; Ampersand
    { {loc = $loc; pattern; dattr = Dmut; annot = None} }
  | pattern = sexp_pattern; Exclamation
    { {loc = $loc; pattern; dattr = Dmove; annot = None} }
  | pattern = sexp_pattern;
    { {loc = $loc; pattern; dattr = Dnorm; annot = None} }

%inline sexp_decl_typed:
  | id = ident; dattr = option(decl_attr); annot = sexp_type_expr
    { { loc = $loc; pattern = Pvar (fst id, snd id); dattr = pass_attr_of_opt dattr; annot = Some annot } }

%inline decl_attr:
  | Ampersand { Dmut } | Exclamation { Dmove }

%inline sexp_fun:
  | Defn; name = ident; attr = option(attr); option(String_lit); params = maybe_bracks(list(param)); body = list(stmt)
    { ($loc, { name; params; return_annot = None; body; attr }) }

%inline attr:
  | kw = Keyword { $loc, kw }

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

%inline callable_expr:
  | ident { Var (fst $1, snd $1) }
  | e = sexp_expr; f = Accessor {Field ($loc, e, f)}
  | e = sexp_expr; Ldotbrack; i = sexp_expr; Rbrack
    {App ($loc, Var ($loc, "array-get"),
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
  | Let; lets = maybe_bracks(nonempty_list(lets_let)); block = nonempty_list(stmt)
    { make_lets lets block }

%inline lets_let:
  | decl = sexp_decl; pexpr = passed_expr { $loc, decl, pexpr }

%inline passed_expr:
  | pexpr = sexp_expr { {pattr = Dnorm; pexpr} }
  | Ampersand; pexpr = sexp_expr { {pattr = Dmut; pexpr} }
  | Exclamation; pexpr = sexp_expr { {pattr = Dmove; pexpr} }

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
  | Fn; params = maybe_bracks(list(param)); body = list(stmt)
    { Lambda ($loc, params, body) }

%inline sexp_field_set:
  | Set; Ampersand; var = sexp_expr; value = sexp_expr
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

%inline sexp_call:
  | callable_expr { App ($loc, $1, []) }
  | callable_expr; call_arg { App ($loc, $1, [$2]) }
  | callable_expr; a1 = call_arg; args = nonempty_list(call_arg) { App ($loc, $1, a1 :: args) }
  | op = binop; exprs = nonempty_list(sexp_expr) { Bop ($loc, op, exprs) }
  | Builtin_id; list(call_arg) { App ($loc, Var($loc, $1), $2) }

%inline call_arg:
  | amut = option(decl_attr); aexpr = sexp_expr { {apass = pass_attr_of_opt amut; aexpr; aloc = $loc} }

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
  | c = U8 {Plit_char ($loc, c)}
  | tup = bracs(sexp_pattern_tuple) { tup }
  | parens(or_pattern) { $1 }


%inline or_pattern:
  | Or; head = sexp_pattern; tail = nonempty_list(sexp_pattern)
    { Por ($loc, (head :: tail)) }

%inline record_item_pattern:
  | attr = attr; p = option(sexp_pattern) { fst attr, snd attr, p }

%inline ctor_pattern_item:
  | sexp_ctor; sexp_pattern { Pctor ($1, Some $2) }

%inline sexp_pattern_tuple:
  | with_loc(sexp_pattern); list(with_loc(sexp_pattern))
    { Ptup ($loc, $1 :: $2) }

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

%inline sexp_type_expr:
  | sexp_type_list { $1 }
  | parens(sexp_type_func) { $1 }

%inline sexp_type_func:
  | Fun; nonempty_list(sexp_fun_param) { Ty_func $2 }

%inline sexp_fun_param:
  | spec = sexp_type_expr; attr = option(decl_attr) { spec, pass_attr_of_opt attr }

sexp_type_list:
  | Lpar; hd = type_spec; tl = nonempty_list(sexp_type_list); Rpar { Ty_list (hd :: tl) }
  | type_spec { $1 }

type_spec:
  | ident { Ty_id (snd $1) }
  | poly_id { $1 }
  | fst = ident; Div_i; lst = separated_nonempty_list(Div_i, ident)
    { Ty_open_id ($loc, flatten_open (fst :: lst) ) }
  | Lbrac; hd = type_spec; tl = nonempty_list(type_spec); Rbrac { Ty_tuple (hd :: tl)}

%inline poly_id:
  | Quote; Lowercase_id { Ty_var $2 }
