%{
    open Ast

    let parse_elseifs loc cond then_ elseifs else_ =
      let rec aux = function
        | [ (loc, cond, blk) ] ->
            let else_ = Option.map (fun b -> Do_block b) else_ in
            Some (If (loc, cond, Do_block blk, else_))
        | (loc, cond, blk) :: tl -> Some (If (loc, cond, Do_block blk, aux tl))
        | [] -> Option.map (fun b -> Do_block b) else_
      in
      If (loc, cond, Do_block then_, aux elseifs)

    let pass_attr_of_opt = function
      | Some (Ast.Dmut | Dset) -> Ast.Dmut
      | Some Dmove -> Dmove
      | Some Dnorm | None -> Dnorm
%}

%token Eof
%token Fun
%token Let
%token <string> Ident
%token Equal
%token Colon
%token Comma
%token Begin
%token End
%token Rpar
%token Lpar
%token Lbrack
%token Rbrack
%token Lbrac
%token Rbrac
%token <string> Ctor
%token <string> Path_id
%token Dot
%token Import
%token If
%token Elseif
%token Else
%token Ampersand
%token Exclamation
%token Wildcard
%token <int> Int
%token <char> U8
%token <int> U16
%token <float> Float
%token <int> I32
%token <float> F32
%token <string> String_lit
%token True
%token False
%token Hashtag_brack
%token <int> Hashnum_brack
%token Newline
%token Left_arrow
%token Right_arrow
%token Pipe_tail
%token With
%token Do
%token Fmt
%token Hbar
%token Match
%token Quote
%token Type
%token External
%token Module
%token Signature
%token Functor
%token Module_type
%token <string> Builtin_id
%token Val
%token Rec

/* ops  */
%token Equal_binop
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
%token <string> Sized_ident
%token <string> Unknown_sized_ident

%nonassoc Below_Ampersand

%nonassoc Type_application

%nonassoc Below_hbar
%nonassoc Hbar

%nonassoc Ctor

%nonassoc If_no_else
%nonassoc Elseif
%nonassoc Else
%left Right_arrow Pipe_tail
%left And Or
%left Equal_binop Bin_equal_f
%nonassoc Less_i Less_f Greater_i Greater_f Less_eq_i Greater_eq_i Greater_eq_f Less_eq_f
%left Plus_i Plus_f Minus_i Minus_f
%left Mult_i Mult_f Div_i Div_f
%left Dot Ampersand Exclamation
%left Lpar
%left Path Hashtag_brack

%start <Ast.prog> prog

%%

prog:
  | sgn = loption(signature); prog = separated_list(Newline, top_item); Eof { sgn, prog }

top_item:
  | stmt = stmt { Stmt stmt }
  | typedef = typedef { Typedef ($loc, typedef) }
  | ext = ext { Ext_decl ext }
  | modul = modul { modul }
  | functor_ = functor_ { functor_ }
  | modtype = modtype { modtype }

stmt:
  | Let; decl = let_decl; Equal; pexpr = passed_expr { Let($loc, decl, pexpr)  }
  | Let; decl = let_decl; Equal; id = Builtin_id
    { let expr = {pattr = Dnorm; pexpr = Var($loc(id), id)} in Let($loc, decl, expr) }
  | Fun; func = func { let loc, func = func in Function (loc, func) }
  | Fun; Rec; func = func; And; tail = separated_nonempty_list(And, func)
    { Rec($loc, func :: tail) }
  | expr = expr { Expr ($loc, expr) }
  | Import; path = import_path { Import ($loc(path), path) }

func:
  | name = ident; params = parens(param_decl); attr = loption(capture_copies);
      return_annot = option(return_annot); Colon; body = block
    { ($loc, { name; params; return_annot; body; attr }) }

typedef:
  | Type; name = decl_typename; Equal; Lbrac; labels = separated_nonempty_list(Comma, record_item_decl); Rbrac
    { Trecord ({name; labels = Array.of_list labels}) }
  | Type; name = decl_typename; Equal; spec = type_spec { Talias (name, spec) }
  | Type; name = decl_typename; Equal; ctors = separated_nonempty_list(Hbar, ctor)
    { Tvariant ({name; ctors}) }
  | Type; name = decl_typename; Equal; Hbar; ctors = separated_nonempty_list(Hbar, ctor)
    { Tvariant ({name; ctors}) }

ext:
  | External; id = ident; Colon; spec = type_spec { $loc, id, spec, None }
  | External; id = ident; Colon; spec = type_spec; Equal; name = String_lit { $loc, id, spec, Some name }

modtype:
  | Module_type; name = ident; Colon; Begin; sgn = sig_items; End { Module_type (name, sgn) }

modul:
  | Module; name = module_decl; Colon; Begin; sgn = loption(signature); items = separated_nonempty_list(Newline, top_item); End
    { Module (name, sgn, items) }
  | Module; name = module_decl; Equal; path = path_with_loc { Module_alias (name, Amodule path) }
  | Module; name = module_decl; Equal; app = module_application
    { let p, args = app in Module_alias (name, Afunctor_app (p, args)) }

module_application:
  | path = path_with_loc; args = parens(path_with_loc) { path, args }

path_with_loc:
  | path = import_path { $loc, path }

functor_:
  | Functor; name = module_decl; Lpar; params = separated_nonempty_list(Comma, functor_param); Rpar; Colon;
    Begin; sgn = loption(signature); items = separated_nonempty_list(Newline, top_item); End
    { Functor (name, params, sgn, items) }

functor_param:
  | name = ident; Colon; path = import_path { let loc, name = name in loc, name, path }

ctor:
  | name = ctor_ident { {name; typ_annot = None; index = None} }
  | name = ctor_ident; Lpar; annot = ctor_type_spec; Rpar
    { {name; typ_annot = Some annot; index = None} }
  | name = ctor_ident; Lpar; index = Int; Rpar { {name; typ_annot = None; index = Some index} }

record_item_decl:
  | name = Ident; mut = boption(Ampersand); Colon; spec = type_spec { mut, name, spec }

decl_typename:
  | name = Ident { { name; poly_param = [] } }
  | name = Ident; Lpar; poly_param = separated_nonempty_list(Comma, poly_id); Rpar { { name; poly_param } }

%inline module_decl:
  | name = ident { let loc, name = name in loc, name, None }
  | name = ident; Colon; path = import_path { let loc, name = name in loc, name, Some path }

signature:
  | Signature; Colon; Begin; items = sig_items ; End; option(Newline) { items }

sig_items:
  | items = separated_nonempty_list(Newline, sig_item) { items }

sig_item:
  | typedef = typedef { Stypedef ($loc, typedef) }
  | Type; name = decl_typename { Stypedef ($loc, Tabstract name) }
  | Val; id = ident; Colon; spec = type_spec { Svalue ($loc, (id, spec)) }

block:
  | expr = expr; %prec If_no_else { [Expr ($loc, expr)] }
  | Begin; stmts = separated_nonempty_list(Newline, stmt); End { stmts }

let_decl:
  | pattern = let_pattern { {loc = $loc; pattern; annot = None } }
  | pattern = let_pattern; Colon; annot = type_spec { {loc = $loc; pattern; annot = Some annot} }

only_one_param:
  | pattern = basic_pattern { {loc = $loc; pattern; annot = None} }

param_decl:
  | pattern = param_pattern { {loc = $loc; pattern; annot = None} }
  | pattern = param_pattern; Colon; annot = type_spec { {loc = $loc; pattern; annot = Some annot} }

return_annot:
   | Right_arrow; annot = type_spec { annot }

capture_copies:
  | Lbrack; copies = separated_nonempty_list(Comma, ident); Rbrack
    { let hd = List.hd copies in [Fa_param ((fst hd, "copy"), copies)] }

basic_pattern:
  | id = ident { Pvar ((fst id, snd id), Dnorm) }
  | id = ident; Ampersand { Pvar ((fst id, snd id), Dmut) }
  | id = ident; Exclamation { Pvar ((fst id, snd id), Dmove) }
  | Wildcard; { Pwildcard ($loc, Dnorm) }
  | Wildcard; Exclamation { Pwildcard ($loc, Dmove) }
  | Wildcard; Ampersand { Pwildcard ($loc, Dmut) }

non_or_match_pattern:
  | basic = basic_pattern { basic }
  | id = ctor_ident { Pctor (id, None) }
  | id = ctor_ident; Lpar; pattern = match_pattern; Rpar { Pctor (id, Some pattern)  }
  | id = ctor_ident; Lpar; pattern = tup_pattern(match_pattern); Rpar { Pctor (id, Some pattern)  }
  | Lpar; tup = tup_pattern(match_pattern); Rpar { tup }
  | rec_ = record_pattern(match_pattern) { rec_ }
  | i = Int { Plit_int($loc, i) }
  | c = U8 { Plit_char($loc, c) }

match_pattern:
  | pat = non_or_match_pattern { pat }
  | head = non_or_match_pattern; Hbar; tail = separated_nonempty_list(Hbar, non_or_match_pattern)
    { Por ($loc, head :: tail) }

let_pattern:
  | basic = basic_pattern { basic }
  | tup = tup_pattern(basic_pattern) { tup }
  | rec_ = record_pattern(basic_pattern) { rec_ }

param_pattern:
  | basic = basic_pattern { basic }
  | rec_ = record_pattern(param_pattern) { rec_ }
  | Lpar; tups = tup_tups(param_pattern); Rpar { let loc, tups = tups in Ptup (loc, tups, Dnorm) }
  | Lpar; tups = tup_tups(param_pattern); Rpar; Ampersand { let loc, tups = tups in Ptup (loc, tups, Dmut) }
  | Lpar; tups = tup_tups(param_pattern); Rpar; Exclamation { let loc, tups = tups in Ptup (loc, tups, Dmove) }

let tup_pattern(x) :=
  | tups = tup_tups(x); { let loc, tups = tups in Ptup (loc, tups, Dnorm) }

let tup_tups(x) :=
  | head = with_loc(x); Comma; tail = separated_nonempty_list(Comma, with_loc(x));
    { $loc, head :: tail }

let record_pattern(x) :=
  | Lbrac; items = separated_nonempty_list(Comma, record_item_pattern(x)); Rbrac;
    { Precord ($loc, items, Dnorm) }

let record_item_pattern(x) :=
  | ident = ident; Equal; pat = x; { ident, Some pat }
  | ident = ident; { ident, None }

let with_loc(x) :=
  | pat = x; { $loc, pat }

ident:
  | id = Ident { $loc, id }

ctor_ident:
  | id = Ctor { $loc, id }

expr:
  | ident = ident { Var ident }
  | lit = lit { Lit ($loc, lit) }
  | a = expr; bop = binop; b = expr { Bop ($loc, bop, a, b) }
  | unop = unop; expr = expr { Unop ($loc, unop, expr) }
  | If; cond = expr; Colon; then_ = then_
    { let then_, elifs, else_ = then_ in parse_elseifs $loc cond then_ elifs else_ }
  | callee = expr; args = parens(call_arg) { App ($loc, callee, args) }
  | callee = Builtin_id; args = parens(call_arg) { App ($loc, Var($loc(callee), callee), args) }
  | aexpr = expr; Dot; callee = ident; args = parens(call_arg)
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in
      Pipe_head ($loc, arg, Pip_expr (App ($loc, Var callee, args)))}
  | aexpr = expr; apass = decl_attr; callee = ident; args = parens(call_arg)
    { let arg = {apass; aexpr; aloc = $loc(aexpr)} in
      Pipe_head ($loc, arg, Pip_expr (App ($loc, Var callee, args)))}
  | aexpr = expr; Dot; callee = path_ident; args = parens(call_arg)
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in
      Pipe_head ($loc, arg, Pip_expr (App ($loc, callee, args)))}
  | aexpr = expr; apass = decl_attr; callee = path_ident; args = parens(call_arg)
    { let arg = {apass; aexpr; aloc = $loc(aexpr)} in
      Pipe_head ($loc, arg, Pip_expr (App ($loc, callee, args)))}
  | expr = expr; Dot; Fmt; args = parens(expr)
    { Fmt ($loc, expr :: args) }
  | expr = expr; Dot; ident = ident { Field ($loc, expr, snd ident) }
  | Fmt; args = parens(expr) { Fmt ($loc, args) }
  | special = special_builtins { special }
  | Fun; params = parens(param_decl); attr = loption(capture_copies);
      return_annot = option(return_annot); Colon; body = block
    { Lambda ($loc, params, attr, return_annot, body) }
  | Fun; param = only_one_param; attr = loption(capture_copies); Colon; body = block
    { Lambda ($loc, [param], attr, None, body) }
  | Lbrac; items = separated_nonempty_list(Comma, record_item); Rbrac
    { Record ($loc, items) }
  | Lpar; tuple = tuple; Rpar { Tuple ($loc, tuple) }
  | Lpar; expr = expr; Rpar { expr }
  | upcases = upcases { upcases }
  | Lbrac; record = expr; With; items = separated_nonempty_list(Comma, record_item); Rbrac
    { Record_update ($loc, record, items) }
  | Do; Colon; block = block { Do_block block }
  | aexpr = expr; Right_arrow; pipeable = expr
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in
      Pipe_head ($loc, arg, Pip_expr pipeable) }
  | aexpr = expr; Pipe_tail; pipeable = expr
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in
      Pipe_tail ($loc, arg, Pip_expr pipeable) }
  | Match; expr = passed_expr; Colon; option(Hbar); clauses = clauses
    { Match ($loc, expr.pattr, expr.pexpr, clauses) }
  | Match; expr = passed_expr; Colon; clauses = block_clauses
    { Match ($loc, expr.pattr, expr.pexpr, clauses) }
  | Ampersand; expr = expr; Left_arrow; newval = expr; %prec Below_Ampersand
    { Set ($loc, ($loc(expr), expr), newval) }
  | id = Path_id; expr = expr; %prec Path { Local_import ($loc, id, expr) }

path_ident:
  | paths = nonempty_list(Path_id); callee = ident { List.fold_right (fun path expr -> Local_import ($loc, path, expr)) paths (Var callee) }

clauses:
  | clause = clause; %prec Below_hbar { clause :: [] }
  | clause = clause; Hbar; tail = clauses { clause :: tail }

block_clauses:
  | Begin; clauses = separated_nonempty_list(Newline, clause); End { clauses }

clause:
  | pattern = match_pattern; Colon; block = block { $loc, pattern, Do_block block }

special_builtins:
  | e = expr; Dot; Lbrack; i = expr; Rbrack
    {App ($loc, Var ($loc, "__array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}
  | e = expr; Hashtag_brack; i = expr; Rbrack
    {App ($loc, Var ($loc, "__fixed_array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}

upcases:
  | id = ctor_ident; %prec Ctor { Ctor ($loc, id, None) }
  | id = ctor_ident; Lpar; expr = expr; Rpar { Ctor ($loc, id, Some expr) }
  | id = ctor_ident; Lpar; tup = tuple; Rpar {Ctor ($loc, id, Some (Tuple ($loc(tup), tup)))}

tuple:
  | head = expr; Comma; tail = separated_nonempty_list(Comma, expr)
    { head :: tail }

record_item:
  | ident = ident; Equal; expr = expr { ident, expr }
  | ident = ident { ident, Var ($loc, snd ident) }

lit:
  | lit = Int { Int lit }
  | lit = U8  { U8 lit }
  | lit = U16  { U16 lit }
  | lit = bool { Bool  lit }
  | lit = Float { Float lit }
  | lit = I32 { I32 lit }
  | lit = F32 { F32 lit }
  | lit = String_lit { String lit }
  | lit = array_lit { Array lit }
  | Lpar; Rpar { Unit }
  | lit = fixed_array_lit { lit }

bool:
  | True { true }
  | False { false }

array_lit:
  | Lbrack; exprs = separated_list(Comma, expr); Rbrack { exprs }

fixed_array_lit:
  | Hashtag_brack; items = separated_nonempty_list(Comma, expr); Rbrack { Fixed_array items }
  | num = Hashnum_brack; item = expr; Rbrack { Fixed_array_num (num, item) }

call_arg:
  | aexpr = expr { {apass = Dnorm; aexpr; aloc = $loc} }
  | apass = decl_attr; aexpr = expr { {apass; aexpr; aloc = $loc} }

%inline decl_attr:
  | Ampersand { Dmut } | Exclamation { Dmove }

then_:
  | block = block; %prec If_no_else { block, [], None }
  | block = block; elifs = elifs { let elifs, else_ = elifs in block, elifs, Some else_ }

elifs:
  | elifs = nonempty_list(elif); else_ = else_ { elifs, else_ }
  | else_ = else_ { [], else_ }

passed_expr:
  | pexpr = expr { {pattr = Dnorm; pexpr} }
  | Ampersand; pexpr = expr { {pattr = Dmut; pexpr} }
  | Exclamation; pexpr = expr { {pattr = Dmove; pexpr} }

elif:
  | Elseif; cond = expr; Colon; elseblk = block { ($loc, cond, elseblk) }

else_:
  | Else; Colon; item = block; { item }

import_path:
  | id = Ident { Path.Pid (id) }
  | id = Path_id; path = import_path { Path.Pmod (id, path)  }

type_path:
  | id = Path_id; path = type_path_cont { Path.Pmod (id, path)  }

type_path_cont:
  | id = Path_id; path = type_path_cont { Path.Pmod (id, path)  }
  | id = Ident { Path.Pid (id) }

%inline unop:
  | Minus_i { Uminus_i }
  | Minus_f { Uminus_f }

%inline binop:
  | Equal_binop { Equal_i }
  | Plus_i  { Plus_i }
  | Minus_i { Minus_i }
  | Mult_i  { Mult_i }
  | Div_i   { Div_i }
  | Less_i  { Less_i }
  | Greater_i { Greater_i }
  | Less_eq_i  { Less_eq_i }
  | Greater_eq_i { Greater_eq_i }
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

let parens(x) :=
  | Lpar; items = separated_list(Comma, x); Rpar; { items }

type_spec:
  | id = Ident { Ty_id id }
  | id = poly_id { Ty_var id }
  | id = Sized_ident { Ty_id id }
  | id = Unknown_sized_ident { Ty_id id }
  | path = type_path { Ty_import_id ($loc, path) }
  | head = type_spec; Lpar; tail = separated_nonempty_list(Comma, type_spec); Rpar
    { Ty_applied (head :: tail) }
  | Lpar; Rpar; Right_arrow; ret = type_spec; %prec Type_application
    { Ty_func ([Ty_id "unit", Dnorm; ret, Dnorm]) }
  | Lpar; spec = tup_or_fun { spec }

tup_or_fun:
  /* One param function */
  | spec = type_spec; Rpar; Right_arrow; ret = type_spec; %prec Type_application { Ty_func ([spec, Dnorm; ret, Dnorm]) }
  /* decl_attr means it's a function */
  | spec = type_spec; attr = decl_attr; cont = continue_fun { Ty_func ((spec, attr) :: cont) }
  /* More than one param, either function or tuple */
  | one = type_spec; Comma; two = type_spec; attr = decl_attr; cont = continue_fun
    { Ty_func ((one, Dnorm) :: (two, attr) :: cont) }
  | one = type_spec; Comma; two = type_spec; cont = continue_tup_or_fun
    { let func, params = cont in
      if func then Ty_func ((one, Dnorm) :: (two, Dnorm) :: params)
      else Ty_tuple (one :: two :: (List.map fst params))}

continue_tup_or_fun:
  | Rpar { false, [] }
  | Rpar; Right_arrow; ret = type_spec; %prec Type_application { true, [ret, Dnorm] }
  | Comma; spec = type_spec; cont = continue_tup_or_fun { let kind, cont = cont in kind, ((spec, Dnorm) :: cont) }
  | Comma; spec = type_spec; attr = decl_attr; cont = continue_fun { true, ((spec, attr) :: cont) }

continue_fun:
  | Rpar; Right_arrow; ret = type_spec; %prec Type_application { [ret, Dnorm] }
  | Comma; spec = type_spec; attr = option(decl_attr); cont = continue_fun { (spec, pass_attr_of_opt attr) :: cont }

ctor_type_spec:
  | normal = type_spec { normal }
  | head = type_spec; Comma; tail = separated_nonempty_list(Comma, type_spec)
    { Ty_tuple (head :: tail) }

poly_id:
  | Quote; id = Ident { id }
