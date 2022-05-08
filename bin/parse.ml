open Lexing
open Schmulang
module E = MenhirLib.ErrorReports
module L = MenhirLib.LexerUtil
module I = UnitActionsParser.MenhirInterpreter

let pp_position lexbuf file =
  let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
  let pos = lexbuf.lex_curr_p in
  let pos =
    Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)
  in
  (pp, pos)

let loc_of_lexing lexbuf =
  Pp_loc.Position.(of_lexing lexbuf.lex_start_p, of_lexing lexbuf.lex_curr_p)

let parse_fast file =
  let src, lexbuf = L.read file in

  try Ok (Parser.prog Indent.insert_ends lexbuf) with
  | Lexer.SyntaxError msg ->
      let loc = loc_of_lexing lexbuf in
      let pp, pos = pp_position lexbuf file in
      Error (`Lex (Format.asprintf "%s:%s %s\n%!%a" file pos msg pp [ loc ]))
  | Parser.Error -> Error (`Parse src)

(* The following couple of functions are copied from the menhir example
   'calc-syntax-errors/calc.ml' or slightly adapted *)

let env checkpoint =
  match checkpoint with I.HandlingError env -> env | _ -> assert false

let state checkpoint : int =
  match I.top (env checkpoint) with
  | Some (I.Element (s, _, _, _)) -> I.number s
  | None -> 0

(* [show text (pos1, pos2)] displays a range of the input text [text]
   delimited by the positions [pos1] and [pos2]. *)

let show text positions =
  E.extract text positions |> E.sanitize |> E.compress
  |> E.shorten 20 (* max width 43 *)

(* [get text checkpoint i] extracts and shows the range of the input text that
   corresponds to the [i]-th stack cell. The top stack cell is numbered zero. *)

let get text checkpoint i =
  match I.get i (env checkpoint) with
  | Some (I.Element (_, _, pos1, pos2)) -> show text (pos1, pos2)
  | None ->
      (* The index is out of range. This should not happen if [$i]
         keywords are correctly inside the syntax error message
         database. The integer [i] should always be a valid offset
         into the known suffix of the stack. *)
      "???"

let succeed _v = failwith "Internal Error: Should not succeed from parser error"

(* [fail text buffer checkpoint] is invoked when parser has encountered a
   syntax error. *)

let fail src file lexbuf (checkpoint : _ I.checkpoint) =
  let loc = loc_of_lexing lexbuf in
  let pp, pos = pp_position lexbuf file in

  (* let message = Syntax_errors.message (state checkpoint) in *)
  let message = "nope" in
  (* Expand away the $i keywords that might appear in the message. *)
  let message = E.expand (get src checkpoint) message in

  let msg =
    Format.asprintf "%s:%s %s: %s\n%!%a" file pos "Syntax error" message pp
      [ loc ]
  in
  Error msg

let generate_error file src =
  (* Allocate and initialize a lexing buffer. *)
  let lexbuf = L.init file (Lexing.from_string src) in
  (* Wrap the lexer and lexbuf together into a supplier, that is, a
     function of type [unit -> token * position * position]. *)
  let supplier = I.lexer_lexbuf_to_supplier Indent.insert_ends lexbuf in

  let checkpoint = UnitActionsParser.Incremental.prog lexbuf.lex_curr_p in
  (* Run the parser. *)
  (* We do not handle [Lexer.Error] because we know that we will not
     encounter a lexical error during this second parsing run. *)
  I.loop_handle succeed (fail src file lexbuf) supplier checkpoint

let parse file =
  match parse_fast file with
  | Ok ast -> Ok ast
  | Error (`Lex msg) -> Error msg
  | Error (`Parse src) -> generate_error file src
