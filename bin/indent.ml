open Schmulang

module Temp = struct
  type mytokens = Parser.token =
    | Uppercase_id of string
    | U8 of char
    | Type
    | True
    | Then
    | String_lit of string
    | Rpar
    | Rbrack
    | Rbrac
    | Quote
    | Plus_i
    | Plus_f
    | Pipe_tail
    | Or
    | Mutable
    | Mult_i
    | Mult_f
    | Minus_i
    | Minus_f
    | Lpar
    | Lowercase_id of string
    | Less_i
    | Less_f
    | Lbrack
    | Lbrac
    | Int of int
    | If
    | I32 of int
    | Greater_i
    | Greater_f
    | Fun
    | Float of float
    | False
    | F32 of float
    | External
    | Equal
    | Eof
    | End
    | Elseif
    | Else
    | Dot
    | Div_i
    | Div_f
    | Comma
    | Colon
    | Builtin_id of string
    | Bin_equal_i
    | Bin_equal_f
    | Begin
    | Arrow_right
    | Arrow_left
    | And
  [@@deriving show]
end

exception Indent_error

type state =
  | Default
  | Marked of int
    (* We have reached a special token and a block might start. Stores line number *)
  | Indent
  | Dedent of int
(* We emit [End]s until the indentation matches again. Stores column number *)

let state = ref Default
let indents = ref [ 0 ]
let cached_token = ref None
let mark pos = state := Marked Lexing.(pos.pos_lnum)

let get_cnum lexbuf =
  let pos = Lexing.(lexbuf.lex_start_p) in
  pos.pos_cnum - pos.pos_bol

let emit lexbuf (token : Parser.token) =
  match token with
  | Equal | Arrow_right | Then | Else as token ->
      state := Marked Lexing.(lexbuf.lex_curr_p.pos_lnum);
      token
  | token -> token

let dedent lexbuf cnum =
  (* We emit [End] until we found the matching indentation *)
  match !indents with
  | [] -> raise Indent_error
  | column :: tl ->
      if cnum < column then (
        (* Still dedenting *)
        indents := tl;
        Parser.(End))
      else if cnum = column then (
        state := Default;
        (* We have reached the correct indent *)
        match !cached_token with
        | Some token -> emit lexbuf token
        | None ->
            failwith "Internal indent error")
      else
        (* We have missing our column  *)
        raise Indent_error

let indent lexbuf =
  (* The indentation happens in [read_marked], we just emit the cached token *)
  state := Default;
  match !cached_token with
  | Some token -> emit lexbuf token
  | None ->
      failwith "Internal indent error"

let read_default lexbuf =
  let token = Lexer.read lexbuf in

  let indent_cnum = List.hd !indents in
  let cnum = get_cnum lexbuf in
  if cnum < indent_cnum then (
    (* We are dedenting *)
    cached_token := Some token;
    state := Dedent cnum;
    dedent lexbuf cnum)
  else emit lexbuf token

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
    raise Indent_error

let string_of_state = function
  | Default -> "default"
  | Marked lnum -> Printf.sprintf "marked %i" lnum
  | Indent -> "indent"
  | Dedent cnum -> Printf.sprintf "dedent %i" cnum

let insert_ends lexbuf =
  (* print_endline (string_of_state !state); *)
  (* print_endline (Lexing.lexeme lexbuf); *)
  match !state with
  | Default -> read_default lexbuf
  | Marked lnum -> read_marked lexbuf lnum
  | Indent -> indent lexbuf
  | Dedent cnum -> dedent lexbuf cnum
