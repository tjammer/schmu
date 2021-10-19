open Lexing
open Schmulang

let print_position _ lexbuf =
  let pos = lexbuf.lex_curr_p in
  Printf.sprintf "%s:%d:%d" pos.pos_fname pos.pos_lnum
    (pos.pos_cnum - pos.pos_bol + 1)

let run src =
  let lexbuf = Lexing.from_string src in
  Schmulang.(
    try
      let prog = Parser.prog Lexer.read lexbuf in
      Ok
        (let externals, typ = Typing.to_typed prog in
         ignore (Codegen.generate externals typ);
         Llvm.dump_module Codegen.the_module;
         typ.typ)
    with
    | Lexer.SyntaxError msg ->
        Error (Printf.sprintf "%a: %s" print_position lexbuf msg)
    | Parser.Error ->
        Error (Printf.sprintf "%a: syntax error" print_position lexbuf)
    | Typing.Error (_, msg) -> Error msg)

let run_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  match run s with
  | Ok typ -> Typing.string_of_type typ |> print_endline
  | Error msg -> prerr_endline msg

let rec run_prompt () =
  try
    print_string "> ";
    (match run (read_line ()) with
    | Ok typ -> Typing.string_of_type typ |> print_endline
    | Error msg -> prerr_endline msg);
    run_prompt ()
  with End_of_file -> ()

let () =
  if Array.length Sys.argv > 2 then (
    print_endline "Usage: schmu [script]";
    exit 64)
  else if Array.length Sys.argv = 2 then run_file Sys.argv.(1)
  else run_prompt ()
