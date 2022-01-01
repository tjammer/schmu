open Lexing
open Schmulang

let pp_position lexbuf file =
  let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
  let pos = lexbuf.lex_curr_p in
  let pos =
    Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)
  in
  (pp, pos)

let run file src =
  let lexbuf = Lexing.from_string src in
  Schmulang.(
    try
      let prog = Parser.prog Lexer.read lexbuf in
      Ok
        (let tree = Typing.to_typed prog |> Monomorph_tree.monomorphize in
         ignore (Codegen.generate tree);
         Llvm.dump_module Codegen.the_module;
         tree.tree.typ)
    with
    | Lexer.SyntaxError msg ->
        let loc = (lexbuf.lex_start_p, lexbuf.lex_curr_p) in
        let pp, pos = pp_position lexbuf file in
        Error (Format.asprintf "%s:%s %s\n%a" file pos msg pp [ loc ])
    | Parser.Error ->
        let loc = (lexbuf.lex_start_p, lexbuf.lex_curr_p) in
        let pp, pos = pp_position lexbuf file in
        Error
          (Format.asprintf "%s:%s %s\n%a" file pos "syntax error" pp [ loc ])
    | Typing.Error (loc, msg) ->
        let errloc = fst loc in
        let pp, _ = pp_position lexbuf file in
        Error
          (Format.asprintf "%s:%d:%d: error: %s\n%a" file errloc.pos_lnum
             (errloc.pos_cnum - errloc.pos_bol + 1)
             msg pp [ loc ]))

let run_file filename =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  match run filename s with
  | Ok typ -> Typing.string_of_type typ |> print_endline
  | Error msg -> prerr_endline msg

let rec run_prompt () =
  try
    print_string "> ";
    (match run "" (read_line ()) with
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
