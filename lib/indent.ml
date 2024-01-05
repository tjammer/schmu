exception Error of string

type state_kind =
  | Default
  | Marked of int
    (* We have reached a special token and a block might start. Stores line number *)
  | Indent
  | Dedent of int
  | Newline
(* We emit [End]s until the indentation matches again. Stores column number *)

type state = {
  kind : state_kind;
  first : bool;
  indents : int list;
  cached : Parser.token option;
  parens : int list;
      (* Saving the indentation of opening parens let's us close indented blocks
         with the outer paren. This is useful in higher-order functions. Otherwise,
         the closing paren would have to go to another line to the original column.
         The parser takes care that the correct paren is used, we don't have to
         distinguish them. Thus, we only save the column number. *)
}

let default =
  { kind = Default; first = true; indents = [ 0 ]; cached = None; parens = [] }

let saved_state = ref default
let mark state pos = { state with kind = Marked Lexing.(pos.pos_lnum) }
let reset () = saved_state := default

let get_cnum lexbuf =
  let pos = Lexing.(lexbuf.lex_start_p) in
  pos.pos_cnum - pos.pos_bol

let rec emit state lexbuf (token : Parser.token) =
  match token with
  | Colon ->
      let state = mark state Lexing.(lexbuf.lex_curr_p) in
      (token, state)
  | Eof -> (
      (* Insert dedents before Eof if there still is indentation *)
      match state.indents with
      | [] -> raise (Error "Inconsistent indentation")
      | [ _ ] -> (token, state)
      | _ :: _ ->
          dedent { state with kind = Dedent 0; cached = Some token } lexbuf 0)
  | Lpar | Lbrac | Lbrack | Hashtag_brack | Hashnum_brack _ ->
      (token, { state with parens = List.hd state.indents :: state.parens })
  | Rbrac | Rbrack | Rpar -> (
      match (state.parens, state.indents) with
      | parcol :: tl, cnum :: _ ->
          (* Leave the parcol in state until the indent is correct *)
          if parcol < cnum then
            dedent
              { state with kind = Dedent parcol; cached = Some token }
              lexbuf parcol
          else (token, { state with parens = tl })
      | [], _ -> (token, state)
      | _, _ -> failwith "Internal Error in parens thing")
  | token -> (token, state)

and maybe_newline state lexbuf =
  match state.cached with
  | Some
      (( Parser.Rbrac | Rbrack | Rpar | Right_arrow | Pipe_tail | Else | Elseif
       | And | Eof ) as token) ->
      (* These tokes should be able to be placed on the outer indent without
         starting a new line. *)
      emit { state with kind = Default } lexbuf token
  | _ -> (Newline, { state with kind = Newline })

and dedent state lexbuf cnum =
  (* We emit [End] until we found the matching indentation *)
  match state.indents with
  | [] -> raise (Error "Inconsintent indentation")
  | column :: tl ->
      if cnum < column then
        ((* Still dedenting *)
         Parser.(End), { state with indents = tl })
      else if cnum = column then
        (* We have reached the correct indent *)
        maybe_newline state lexbuf
      else
        (* We have missed our column  *)
        raise (Error "Inconsintent indentation")

let indent state lexbuf =
  (* The indentation happens in [read_marked], we just emit the cached token *)
  match state.cached with
  | Some token -> emit { state with kind = Default } lexbuf token
  | None -> failwith "Internal indent error"

let newline = indent

let read_default state lexbuf =
  let token = Lexer.read lexbuf in

  let indent_cnum = List.hd state.indents in
  let cnum = get_cnum lexbuf in
  (* let state = *)
  (*   match token with *)
  (*   | Lpar | Lbrac | Lbrack | Hashtag_brack | Hashnum_brack _ -> *)
  (*       Printf.printf "incr parens to %i\n%!" cnum; *)
  (*       { state with parens = cnum :: state.parens } *)
  (*   | _ -> state *)
  (* in *)
  if cnum < indent_cnum then
    (* We are dedenting *)
    dedent { state with cached = Some token; kind = Dedent cnum } lexbuf cnum
  else if cnum = indent_cnum && not state.first then
    maybe_newline { state with cached = Some token } lexbuf
  else emit { state with first = false } lexbuf token

let read_marked state lexbuf lnum =
  let next_token = Lexer.read lexbuf in
  let pos = lexbuf.lex_start_p in
  let cnum = pos.pos_cnum - pos.pos_bol in

  let indent_cnum = List.hd state.indents in
  (* If we are on the same line, there is no indent *)
  if lnum = pos.pos_lnum then
    emit { state with kind = Default } lexbuf next_token
  else if cnum > indent_cnum then
    ( (* Save the token to emit on next call and insert [Begin] *)
      Parser.(Begin),
      {
        state with
        indents = cnum :: state.indents;
        kind = Indent;
        cached = Some next_token;
      } )
  else
    (* We are on a new line after [Equal], but not indented *)
    raise (Error "Expected an indented line")

let insert_ends lexbuf =
  let token, state =
    match !saved_state.kind with
    | Default -> read_default !saved_state lexbuf
    | Marked lnum -> read_marked !saved_state lexbuf lnum
    | Indent -> indent !saved_state lexbuf
    | Dedent cnum -> dedent !saved_state lexbuf cnum
    | Newline -> newline !saved_state lexbuf
  in
  saved_state := state;
  token
