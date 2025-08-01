(* Add semicolons. The grammar is written with semicolons separating statements
   / unit expressions in blocks. After certain newlines, we add Semicolons here
   between lexer and parser. How it works: Newlines are ignored for most tokens,
   except tokens which can mark the end of an expression, except when the
   following token can continue the expression. *)

type state = { last : Parser.token; lnum : int; buffered : Parser.token option }

let default_state = { last = Parser.Lcurly; lnum = 0; buffered = None }
let saved_state = ref default_state
let reset () = saved_state := default_state

let default next state =
  saved_state := { state with last = next };
  next

let continues_expr = function
  | Parser.Dot | Else | Or | And | Hbar | Pipe | Pipe_last | Mult_op _
  | Cmp_op _ | Eq_op _ | Plus_op _ ->
      true
  | _ -> false

let rec newline ~lnum lexbuf next state =
  match (state.last, next) with
  | _, (Parser.Eof | Rcurly | Rbrack | Rpar) ->
      (* These tokens end a block or expression or the file. Don't insert a
         semicolon in these cases *)
      default next { state with lnum }
  | Parser.Semicolon, Semicolon ->
      (* Ignore following semicolons *)
      saved_state := { state with lnum };
      read lexbuf
  | ( ( Parser.Rpar | Ident _ | Builtin_id _ | Rbrack | Rcurly | Int _ | Float _
      | U8 _ | U16 _ | I32 _ | F32 _ | True | False | String_lit _ | Ctor _ ),
      _ ) ->
      (* These tokens end an expression, insert Semicolon unless an
         expressions continues on next line. *)
      if continues_expr next then default next { state with lnum }
      else (
        saved_state := { lnum; buffered = Some next; last = Semicolon };
        Semicolon)
  | _ -> default next { state with lnum }

and read lexbuf =
  match !saved_state.buffered with
  | Some token ->
      saved_state := { !saved_state with buffered = None };
      token
  | None ->
      let token = Lexer.read lexbuf in
      let pos = Lexing.(lexbuf.lex_start_p) in
      if not (Int.equal pos.pos_lnum !saved_state.lnum) then
        newline ~lnum:pos.pos_lnum lexbuf token !saved_state
      else default token !saved_state
