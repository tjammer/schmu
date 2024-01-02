exception Error of string

type state =
  | Default
  | Marked of int
    (* We have reached a special token and a block might start. Stores line number *)
  | Indent
  | Dedent of int
  | Newline
(* We emit [End]s until the indentation matches again. Stores column number *)

let state = ref Default
let first = ref true
let indents = ref [ 0 ]
let cached_token = ref None
let mark pos = state := Marked Lexing.(pos.pos_lnum)

let reset () =
  state := Default;
  first := true;
  indents := [ 0 ];
  cached_token := None

let get_cnum lexbuf =
  let pos = Lexing.(lexbuf.lex_start_p) in
  pos.pos_cnum - pos.pos_bol

let emit lexbuf (token : Parser.token) =
  match token with
  | Colon ->
      state := Marked Lexing.(lexbuf.lex_curr_p.pos_lnum);
      token
  | token -> token

let maybe_newline lexbuf =
  match !cached_token with
  | Some
      (( Parser.Rbrac | Rbrack | Rpar | Right_arrow | Pipe_tail | Else | Elseif
       | Eof ) as token) ->
      (* These tokes should be able to be placed on the outer indent without
         starting a new line. *)
      state := Default;
      emit lexbuf token
  | _ ->
      state := Newline;
      Newline

let dedent lexbuf cnum =
  (* We emit [End] until we found the matching indentation *)
  match !indents with
  | [] -> raise (Error "Inconsintent indentation")
  | column :: tl ->
      if cnum < column then (
        (* Still dedenting *)
        indents := tl;
        Parser.(End))
      else if cnum = column then
        let () = print_endline "same" in
        (* We have reached the correct indent *)
        maybe_newline lexbuf
      else
        (* We have missed our column  *)
        raise (Error "Inconsintent indentation")

let indent lexbuf =
  (* The indentation happens in [read_marked], we just emit the cached token *)
  state := Default;
  match !cached_token with
  | Some Colon ->
      print_endline "colon";
      emit lexbuf Colon
  | Some token -> emit lexbuf token
  | None -> failwith "Internal indent error"

let newline = indent

let read_default lexbuf =
  let token = Lexer.read lexbuf in

  let indent_cnum = List.hd !indents in
  let cnum = get_cnum lexbuf in
  if cnum < indent_cnum then (
    (* We are dedenting *)
    cached_token := Some token;
    state := Dedent cnum;
    dedent lexbuf cnum)
  else if cnum = indent_cnum && not !first then (
    cached_token := Some token;
    maybe_newline lexbuf)
  else (
    first := false;
    emit lexbuf token)

let read_marked lexbuf lnum =
  let next_token = Lexer.read lexbuf in
  let pos = lexbuf.lex_start_p in
  let cnum = pos.pos_cnum - pos.pos_bol in

  let indent_cnum = List.hd !indents in
  (* If we are on the same line, there is no indent *)
  if lnum = pos.pos_lnum then (
    state := Default;
    next_token)
  else if cnum > indent_cnum then (
    indents := cnum :: !indents;
    state := Indent;
    (* Save the token to emit on next call and insert [Begin] *)
    cached_token := Some next_token;
    Parser.(Begin))
  else
    (* We are on a new line after [Equal], but not indented *)
    raise (Error "Expected an indented line")

let string_of_state = function
  | Default -> "default"
  | Marked lnum -> Printf.sprintf "marked %i" lnum
  | Indent -> "indent"
  | Dedent cnum -> Printf.sprintf "dedent %i" cnum
  | Newline -> "newline"

let insert_ends lexbuf =
  match !state with
  | Default -> read_default lexbuf
  | Marked lnum -> read_marked lexbuf lnum
  | Indent -> indent lexbuf
  | Dedent cnum -> dedent lexbuf cnum
  | Newline -> newline lexbuf
