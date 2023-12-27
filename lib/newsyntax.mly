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
%token <string> Upcase_ident
%token Dot
%token Import
%token If
%token Elseif
%token Else
%token Ampersand
%token Exclamation
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

%nonassoc If_no_else
%nonassoc Elseif
%nonassoc Else
%left And Or
%nonassoc Less_i Less_f Greater_i Greater_f Less_eq_i Greater_eq_i Greater_eq_f Less_eq_f
%left Plus_i Plus_f Minus_i Minus_f
%left Mult_i Mult_f Div_i Div_f
%left Equal_binop Bin_equal_f
%left Lpar

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
  | Import; path = import_path { Import ($loc(path), path) }

block:
  | expr = expr; %prec If_no_else { [Expr ($loc, expr)] }
  | Begin; stmts = separated_nonempty_list(Newline, stmt); End { stmts }

decl:
  | id = ident { {loc = $loc; pattern = Pvar (id, Dnorm); annot = None } }

ident:
  | id = Ident { $loc, id }

expr:
  | ident = ident { Var ident }
  | lit = lit { Lit ($loc, lit) }
  | a = expr; bop = binop; b = expr { Bop ($loc, bop, [a; b]) }
  | If; cond = expr; Colon; then_ = then_
    { let then_, elifs, else_ = then_ in parse_elseifs $loc cond then_ elifs else_ }
  | callee = expr; args = parens(call_arg) { App ($loc, callee, args) }
  | Fun; params = parens(decl); Colon; body = block
    { Lambda ($loc, params, [], body) }

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

