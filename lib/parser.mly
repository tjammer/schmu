%{
    open Ast

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
%token Rpar
%token Lpar
%token Lbrack
%token Rbrack
%token Lcurly
%token Rcurly
%token <string> Ctor
%token <string> Path_id
%token Dot
%token Use
%token Import
%token If
%token Else
%token Ampersand
%token Exclamation
%token Wildcard
%token <int64> Int
%token <char> U8
%token <int> U16
%token <float> Float
%token <int> I32
%token <float> F32
%token <string> String_lit
%token True
%token False
%token Hash
%token Hash_quest
%token Semicolon
%token Right_arrow
%token Left_arrow
%token Pipe
%token Pipe_last
%token With
%token Hbar
%token Match
%token Quote
%token Type
%token External
%token Module
%token Signature
%token Functor
%token <string> Builtin_id
%token Val
%token Rec

/* ops  */

%token <string> Eq_op
%token <string> Cmp_op
%token <string> Plus_op
%token <string> Mult_op
%token And
%token Or

%nonassoc Below_Ampersand

%nonassoc Type_application

%nonassoc Ctor

%left Pipe Pipe_last
%left And Or
%left Eq_op
%left Cmp_op
%left Plus_op
%left Mult_op
%left Dot
%left Lcurly
%left Lbrack
%left Lpar
%left Path Hash

%start <Ast.prog> prog

%%

prog:
  | prog = separated_list(Semicolon, top_item); Eof { prog }

top_item:
  | stmt = stmt { Stmt stmt }
  | typedef = typedef { Typedef ($loc, typedef) }
  | ext = ext { Ext_decl ext }
  | modul = modul { modul }
  | functor_ = functor_ { functor_ }
  | modtype = modtype { modtype }
  | sgn = signature { Signature ($loc(sgn), sgn) }
  | Import; id = Ident { Import ($loc(id), id) }

stmt_no_ident:
/* Needed to disambiguate block expression from record expression */
  | Let; decl = let_decl; Equal; pexpr = passed(expr)
    { let pattr, pexpr = pexpr in Let($loc, decl, { pattr; pexpr })  }
  | Let; decl = let_decl; Equal; id = Builtin_id
    { let expr = {pattr = Dnorm; pexpr = Var($loc(id), id)} in Let($loc, decl, expr) }
  | Let; decl = let_decl; Left_arrow; callee = ident; args = parens(call_arg)
    { let pexpr = App_borrow (($startpos(callee), $endpos(args)), Var callee, args) in
      Let($loc, decl, { pattr = Dnorm; pexpr }) }
  | Fun; func = func { let loc, func = func false in Function (loc, func) }
  | Fun; Rec; func = func { let loc, func = func true in Function (loc, func) }
  | Fun; Rec; func = func; And; tail = separated_nonempty_list(And, func)
    { Rec($loc, (func true) :: (List.map (fun f -> f true) tail)) }
  | expr = expr_no_ident { Expr ($loc, expr) }
  | Use; path = use_path { Use ($loc(path), path) }

stmt:
  | stmt = stmt_no_ident { stmt }
  | ident = ident { Expr ($loc, (Var ident)) }
  | tuple = tuple { Expr ($loc, Tuple ($loc, tuple)) }

func:
  | name = func_name; params = parens(param_decl); attr = loption(capture_copies);
      return_annot = option(return_annot); body = block
    { fun is_rec -> ($loc, { name; params; return_annot; body; attr; is_rec }) }

func_name:
  | name = ident { name }
  | infix = infix { $loc(infix), infix }

typedef:
  | Type; name = decl_typename; Equal; Lcurly; labels = separated_nonempty_trailing_list(Comma, record_item_decl, Rcurly)
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
  | Module; Type; name = ident; Lcurly; sgn = sig_items; Rcurly { Module_type (name, sgn) }

modul:
  | Module; name = module_decl; Lcurly; items = separated_nonempty_list(Semicolon, top_item); Rcurly
    { Module (name, items) }
  | Module; name = module_decl; Equal; path = path_with_loc { Module_alias (name, Amodule path) }
  | Module; name = module_decl; Equal; app = module_application
    { let p, args = app in Module_alias (name, Afunctor_app (p, args)) }

module_application:
  | path = path_with_loc; args = parens(path_with_loc) { path, args }

path_with_loc:
  | path = use_path { $loc, path }

functor_:
  | Functor; name = module_decl; Lpar; params = separated_list(Comma, functor_param); Rpar;
    Lcurly; items = separated_nonempty_list(Semicolon, top_item); Rcurly
    { Functor (name, params, items) }

functor_param:
  | name = ident; Colon; path = use_path { let loc, name = name in loc, name, path }

ctor:
  | name = ctor_ident { {name; typ_annot = None; index = None} }
  | name = ctor_ident; Lpar; annot = ctor_type_spec; Rpar
    { {name; typ_annot = Some annot; index = None} }
  | name = ctor_ident; Lpar; index = Int; Rpar { {name; typ_annot = None; index = Some (Int64.to_int index)} }

record_item_decl:
  | name = Ident; mut = boption(Ampersand); Colon; spec = type_spec { mut, name, spec }

decl_typename:
  | name = Ident { { name; poly_param = [] } }
  | name = Ident; Lbrack; poly_param = separated_nonempty_list(Comma, poly_id); Rbrack { { name; poly_param } }

module_decl:
  | name = ident { let loc, name = name in loc, name, None }
  | name = ident; Colon; path = use_path { let loc, name = name in loc, name, Some path }

signature:
  | Signature; Lcurly; items = sig_items ; Rcurly { items }

sig_items:
  | items = separated_nonempty_list(Semicolon, sig_item) { items }

sig_item:
  | typedef = typedef { Stypedef ($loc, typedef) }
  | Type; name = decl_typename { Stypedef ($loc, Tabstract name) }
  | Val; id = ident; Colon; spec = type_spec { Svalue ($loc, (id, spec)) }
  | Val; id = infix; Colon; spec = type_spec
    { Svalue ($loc, (($loc(id), id), spec)) }

block:
  | Lcurly; stmts = separated_nonempty_list(Semicolon, stmt); Rcurly { stmts }

let_decl:
  | mode = mode; pattern = let_pattern { {loc = $loc; pattern; annot = None; mode} }
  | mode = mode; pattern = let_pattern; Colon; annot = type_spec
    { {loc = $loc; pattern; annot = Some annot; mode} }

%inline mode:
  | { None }
  | mode = ident { Some(mode) }

only_one_param:
  | pattern = basic_pattern { {loc = $loc; pattern; annot = None; mode = None} }

param_decl:
  | mode = mode; pattern = pattern { {loc = $loc; pattern; annot = None; mode} }
  | mode = mode; pattern = pattern; Colon; annot = type_spec
    { {loc = $loc; pattern; annot = Some annot; mode} }

return_annot:
   | Right_arrow; annot = type_spec { annot, $loc(annot) }

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
  | infix = infix { Pvar (($loc(infix), infix), Dnorm) }
  | rec_ = record_pattern(pattern) { rec_ }
  | i = Int { Plit_int($loc, i) }
  | c = U8 { Plit_char($loc, c) }
  | id = ctor_ident { Pctor (id, None) }
  | id = ctor_ident; Lpar; pattern = pattern; Rpar { Pctor (id, Some pattern)  }
  | id = ctor_ident; Lpar; pattern = inner_tup_pattern(pattern); Rpar { Pctor (id, Some pattern)  }

pattern:
  | basic = basic_pattern { basic }
  | tup = tup_patterns { tup }
  | Lpar; pat = pattern; Hbar; pats = separated_nonempty_list(Hbar, pattern); Rpar
    { Por ($loc, pat :: pats) }

match_pattern:
  | pat = pattern { pat }
  | pat = pattern; Hbar; pats = separated_nonempty_list(Hbar, pattern) { Por ($loc, pat :: pats) }

let_pattern:
  | pat = pattern { pat }
  | tups = tup_tups(pattern); { let loc, tups = tups in Ptup (loc, tups, Dnorm) }

tup_patterns:
  | Lpar; tups = tup_tups(pattern); Rpar { let loc, tups = tups in Ptup (loc, tups, Dnorm) }
  | Lpar; tups = tup_tups(pattern); Rpar; Ampersand { let loc, tups = tups in Ptup (loc, tups, Dmut) }
  | Lpar; tups = tup_tups(pattern); Rpar; Exclamation { let loc, tups = tups in Ptup (loc, tups, Dmove) }

inner_tup_pattern(x):
  | tups = tup_tups(x); { let loc, tups = tups in Ptup (loc, tups, Dnorm) }

tup_tups(x):
  | head = with_loc(x); Comma; tail = separated_nonempty_list(Comma, with_loc(x));
    { $loc, head :: tail }

record_pattern(x):
  | Lcurly; items = separated_nonempty_trailing_list(Comma, record_item_pattern(x), Rcurly);
    { Precord ($loc, items, Dnorm) }

record_item_pattern(x):
  | ident = ident; Equal; pat = x; { ident, Some pat }
  | ident = ident; { ident, None }

with_loc(x):
  | pat = x; { $loc, pat }

ident:
  | id = Ident { $loc, id }

%inline ctor_ident:
  | id = Ctor { $loc, id }

expr_no_ident:
  | ident = infix { Var ($loc(ident), ident) }
  | lit = lit { Lit ($loc, lit) }
  | a = expr; bop = binop; b = expr { Bop ($loc, bop, a, b) }
  | a = expr; infix = infix; b = expr
    { let a = {apass = Dnorm; aloc = $loc(a); aexpr = a} in
      let b = {apass = Dnorm; aloc = $loc(b); aexpr = b} in
      App ($loc, Var($loc(infix), infix), [a; b]) }
  | op = Plus_op; expr = expr { Unop ($loc, ($loc(op), op), expr) }
  | If; cond = expr; block = block; ifcont = ifcont
    { If($loc, cond, Do_block block, ifcont) }
  | callee = expr; args = parens(call_arg) { App ($loc, callee, args) }
  | callee = Builtin_id; args = parens(call_arg) { App ($loc, Var($loc(callee), callee), args) }
  | aexpr = expr; inverse = pipe; pipeable = expr
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in
      Pipe ($loc, arg, pipeable, inverse) }
  | expr = expr; Dot; ident = ident { Field ($loc, expr, snd ident) }
  | lambda = lambda { lambda }
  | special = special_builtins { special }
  | Lcurly; items = separated_nonempty_trailing_list(Comma, record_item, Rcurly)
    { Record ($loc, items) }
  | Lcurly; fst = stmt_no_ident; cont = block_cont
    /* A block expression needs to have at least two items */
    { Do_block (fst :: cont) }
  | Lpar; tuple = tuple; Rpar { Tuple ($loc, tuple) }
  | Lpar; expr = expr; Rpar { expr }
  | upcases = upcases { upcases }
  | Lcurly; record = expr; With; items = separated_nonempty_trailing_list(Comma, record_item, Rcurly)
    { Record_update ($loc, record, items) }
  | Match; expr = passed(expr); Lcurly; clauses = clauses; Rcurly
    { Match (($startpos, $endpos(expr)), fst expr, snd expr, clauses) }
  | Ampersand; expr = expr; Equal; newval = expr; %prec Below_Ampersand
    { Set ($loc, ($loc(expr), expr), newval) }
  | id = Path_id; expr = expr; %prec Path { Local_use ($loc, id, expr) }

%inline pipe:
  | Pipe { false }
  | Pipe_last { true }

expr:
  | ident = ident { Var ident }
  | expr = expr_no_ident { expr }

block_cont:
  | Rcurly { [] }
  | Semicolon; block = separated_nonempty_list(Semicolon, stmt); Rcurly { block }

lambda:
  | Fun; params = parens(param_decl); attr = loption(capture_copies);
      return_annot = option(return_annot); body = block
    { Lambda ($loc, params, attr, return_annot, body) }
  | Fun; param = only_one_param; attr = loption(capture_copies); body = block
    { Lambda ($loc, [param], attr, None, body) }

clause_path:
  | paths = nonempty_list(Path_id)
    { List.fold_right (fun s -> function None -> Some (Path.Pid s) | Some p -> Some (Pmod(s, p))) paths None
      |> Option.get }

clause:
  | cpath = option(clause_path); cpat = match_pattern; guard = option(guard); Right_arrow; expr = expr
    { { cloc = $loc; cpath; cpat; guard }, expr }

guard:
  | And; expr = expr { $loc, expr }

clauses:
  | clause = clause { [ clause ] }
  | clause = clause; clause_sep; clauses = clauses
    { clause :: clauses }

clause_sep:
  | Semicolon {  }
  | Hbar {  }

special_builtins:
  | e = expr; Dot; Lbrack; i = expr; Rbrack
    {App ($loc, Var ($loc, "__array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}
  | e = expr; Hash; Lbrack; i = expr; Rbrack
    {App ($loc, Var ($loc, "__fixed_array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}

upcases:
  | id = ctor_ident { Ctor ($loc, id, None) }
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
  | Lbrack; exprs = separated_trailing_list(Comma, expr, Rbrack) { exprs }

separated_nonempty_trailing_list(sep, item, terminator):
  | x = item; option(sep); terminator { [ x ] }
  | x = item; sep; xs = separated_nonempty_trailing_list(sep, item, terminator) { x :: xs }

separated_trailing_list(sep, item, terminator):
  | terminator { [] }
  | lst = separated_nonempty_trailing_list(sep, item, terminator) { lst }

fixed_array_lit:
  | Hash; Lbrack; items = separated_nonempty_trailing_list(Comma, expr, Rbrack) { Fixed_array items }
  | Hash; num = Int; Lbrack; item = expr; Rbrack { Fixed_array_num (Int64.to_int num, item) }

call_arg:
  | aexpr = expr { {apass = Dnorm; aexpr; aloc = $loc} }
  | apass = decl_attr; aexpr = expr { {apass; aexpr; aloc = $loc} }

%inline decl_attr:
  | Ampersand { Dmut } | Exclamation { Dmove }

ifcont:
  | { None}
  | Else; block = block { Some (Do_block block) }
  | Else If cond = expr; block = block; ifcont = ifcont
    { Some (If($loc, cond, Do_block block, ifcont)) }

passed(x):
  | pexpr = x { Dnorm, pexpr }
  | Ampersand; pexpr = x { Dmut, pexpr }
  | Exclamation; pexpr = x { Dmove, pexpr }

use_path:
  | id = Ident { Path.Pid (id) }
  | id = Path_id; path = use_path { Path.Pmod (id, path)  }

type_path:
  | id = Path_id; path = type_path_cont { Path.Pmod (id, path)  }

type_path_cont:
  | id = Path_id; path = type_path_cont { Path.Pmod (id, path)  }
  | id = Ident { Path.Pid (id) }

%inline infix:
  | id = Eq_op { id }
  | id = Cmp_op { id }
  | id = Plus_op { id }
  | id = Mult_op { id }

%inline binop:
  | And     { And }
  | Or      { Or }

parens(x):
  | Lpar; items = separated_list(Comma, x); Rpar; { items }

type_spec:
  | id = ident { Ty_id id }
  | id = poly_id { Ty_var ($loc(id), id) }
  | id = Ident; Hash; i = Int { Ty_id ($loc(id), id ^ "#" ^ (Int64.to_string i)) }
  | id = Ident; Hash_quest { Ty_id ($loc(id), id ^ "#?") }
  | path = type_path { Ty_use_id ($loc, path) }
  | head = type_spec; Lbrack; tail = separated_nonempty_list(Comma, type_spec); Rbrack
    { Ty_applied (head :: tail) }
  | Fun; Lpar; Rpar; Right_arrow; ret = type_spec; %prec Type_application
    { Ty_func ([None, Ty_id ($loc, "unit"), Dnorm; None, ret, Dnorm]) }
  | Fun; Lpar; ps = separated_nonempty_list(Comma, type_param); Rpar; Right_arrow; ret = type_spec;
    %prec Type_application
    { Ty_func (ps @ [None, ret, Dnorm]) }
  | Lpar; ts = separated_nonempty_list(Comma, type_spec); Rpar { Ty_tuple ts }

type_param:
  | mode = mode; spec = type_spec { mode, spec, Dnorm }
  | mode = mode; spec = type_spec; attr = decl_attr { mode, spec, attr }

ctor_type_spec:
  | normal = type_spec { normal }
  | head = type_spec; Comma; tail = separated_nonempty_list(Comma, type_spec)
    { Ty_tuple (head :: tail) }

poly_id:
  | Quote; id = Ident { id }
