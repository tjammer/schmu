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
%token <string> Upcase_ident
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
%token Pipe_head
%token Pipe_tail
%token With
%token Do
%token Fmt

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

%left Pipe_head Pipe_tail
%nonassoc If_no_else
%nonassoc Elseif
%nonassoc Else
%left And Or
%nonassoc Less_i Less_f Greater_i Greater_f Less_eq_i Greater_eq_i Greater_eq_f Less_eq_f
%left Plus_i Plus_f Minus_i Minus_f
%left Mult_i Mult_f Div_i Div_f
%left Equal_binop Bin_equal_f
%left Lpar
%nonassoc Ctor
%left Dot Path Hashtag_brack

%start <Ast.prog> prog

%%

prog:
  | prog = separated_list(Newline, top_item); Eof { [], prog }

top_item:
  | stmt = stmt { Stmt stmt }

stmt:
  | decl = decl; Equal; pexpr = passed_expr { Let($loc, decl, pexpr)  }
  | Fun; name = ident; params = parens(decl); Colon; body = block
    { Function ($loc, { name; params; return_annot = None; body; attr = [] }) }
  | expr = expr { Expr ($loc, expr) }
  | Ampersand; expr = expr; Left_arrow; newval = expr
    { Expr ($loc, Set ($loc, ($loc(expr), expr), newval)) }
  | Import; path = import_path { Import ($loc(path), path) }

block:
  | expr = expr; %prec If_no_else { [Expr ($loc, expr)] }
  | Begin; stmts = separated_nonempty_list(Newline, stmt); End { stmts }

decl:
  | pattern = pattern { {loc = $loc; pattern; annot = None } }

pattern:
  | id = ident { Pvar ((fst id, snd id), Dnorm) }
  | id = ident; Ampersand { Pvar ((fst id, snd id), Dmut) }
  | id = ident; Exclamation { Pvar ((fst id, snd id), Dmove) }
  | Wildcard; { Pwildcard ($loc, Dnorm) }
  | Wildcard; Exclamation { Pwildcard ($loc, Dmove) }
  | Wildcard; Ampersand { Pwildcard ($loc, Dmut) }
  | id = upcase_ident { Pctor (id, None) }
  | id = upcase_ident; pattern = pattern { Pctor (id, Some pattern)  }
/* TODO tup pattern */

ident:
  | id = Ident { $loc, id }

upcase_ident:
  | id = Upcase_ident { $loc, id }

expr:
  | ident = ident { Var ident }
  | lit = lit { Lit ($loc, lit) }
  | a = expr; bop = binop; b = expr { Bop ($loc, bop, [a; b]) }
  | If; cond = expr; Colon; then_ = then_
    { let then_, elifs, else_ = then_ in parse_elseifs $loc cond then_ elifs else_ }
  | callee = expr; args = parens(call_arg) { App ($loc, callee, args) }
  | Fmt; args = parens(expr) { Fmt ($loc, args) }
  | special = special_builtins { special }
  | Fun; params = parens(decl); Colon; body = block
    { Lambda ($loc, params, [], body) }
  | Lbrac; items = separated_nonempty_list(Comma, record_item); Rbrac
    { Record ($loc, items) }
  | tuple = tuple { Tuple ($loc, tuple) }
  | expr = expr; Dot; ident = ident { Field ($loc, expr, snd ident) }
  | Lpar; expr = expr; Rpar { expr }
  | upcases = upcases { upcases }
  | Lbrac; record = expr; With; items = separated_nonempty_list(Comma, record_item); Rbrac
    { Record_update ($loc, record, items) }
  | Do; Colon; block = block { Do_block block }
  | aexpr = expr; Pipe_head; pipeable = expr
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in Pipe_head ($loc, arg, Pip_expr pipeable) }
  | aexpr = expr; Pipe_tail; pipeable = expr
    { let arg = {apass = pass_attr_of_opt None; aexpr; aloc = $loc(aexpr)} in Pipe_tail ($loc, arg, Pip_expr pipeable) }

special_builtins:
  | e = expr; Dot; Lbrack; i = expr; Rbrack
    {App ($loc, Var ($loc, "__array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}
  | e = expr; Hashtag_brack; i = expr; Rbrack
    {App ($loc, Var ($loc, "__fixed_array_get"),
          [{apass = Dnorm; aloc = $loc(e); aexpr = e};
           {apass = Dnorm; aloc = $loc(i); aexpr = i}])}

local_import:
  | id = Upcase_ident; Dot; expr = expr; %prec Path { Local_import ($loc, id, expr) }

upcases:
  | id = upcase_ident; %prec Ctor { Ctor ($loc, id, None) }
  | id = upcase_ident; expr = expr; %prec Ctor { Ctor ($loc, id, Some expr) }
  | id = upcase_ident; Dot; path = local_import { Local_import ($loc, snd id, path) }

tuple:
  | Lpar; head = expr; Comma; tail = separated_nonempty_list(Comma, expr); Rpar
    { head :: tail }
  | Lpar; item = expr; Comma; Rpar { [item] }

record_item:
  | ident = ident; Equal; expr = expr { snd ident, expr }
  | ident = ident { snd ident, Var ($loc, snd ident) }

lit:
  | lit = Int { Int lit }
  | lit = U8  { U8 lit }
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
  | attr = option(decl_attr); aexpr = expr { {apass = pass_attr_of_opt attr; aexpr; aloc = $loc} }

decl_attr:
  | Ampersand { Dmut } | Exclamation { Dmove }

then_:
  | block = block; %prec If_no_else { block, [], None }
  | block = block; elifs = elifs { let elifs, else_ = elifs in block, elifs, Some else_ }

elifs:
  | elifs = nonempty_list(elif); else_ = else_ { elifs, else_ }
  | else_ = else_ { [], else_ }

passed_expr:
  | pexpr = expr { {pattr = Dnorm; pexpr} }

elif:
  | Elseif; cond = expr; Colon; elseblk = block { ($loc, cond, elseblk) }

else_:
  | Else; Colon; item = block; { item }

import_path:
  | id = Upcase_ident { Path.Pid (id) }
  | id = Upcase_ident; Dot; path = import_path { Path.Pmod (id, path)  }

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

