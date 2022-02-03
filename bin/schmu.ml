open Lexing

type opts = { target : string option; dump_llvm : bool }

let pp_position lexbuf file =
  let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
  let pos = lexbuf.lex_curr_p in
  let pos =
    Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)
  in
  (pp, pos)

let run file src { target; dump_llvm } =
  let lexbuf = Lexing.from_string src in
  Schmulang.(
    try
      let prog = Parser.prog Lexer.read lexbuf in
      Ok
        (let tree = Typing.to_typed prog |> Monomorph_tree.monomorphize in
         ignore (Codegen.generate ~target tree);
         if dump_llvm then Llvm.dump_module Codegen.the_module)
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

let run_file filename opts =
  let ch = open_in filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  match run filename s opts with
  | Ok () -> ()
  | Error msg ->
      prerr_endline msg;
      exit 1

let usage = "Usage: schmu [options] filename"

let () =
  let target = ref "" in
  let dump_llvm = ref false in
  let filename = ref [] in
  let anon_fun fn =
    match !filename with
    | [] -> filename := [ fn ]
    | _ ->
        (* We only allow a single filename (for now) *)
        print_endline usage;
        exit 64
  in
  let speclist =
    [
      ( "-target",
        Arg.Set_string target,
        {|triple
    The triple has the general format <arch><sub>-<vendor>-<sys>-<abi>, where:
            arch = x86_64, i386, arm, thumb, mips, etc.
            sub = for ex. on ARM: v5, v6m, v7a, v7m, etc.
            vendor = pc, apple, nvidia, ibm, etc.
            sys = none, linux, win32, darwin, cuda, etc.
            abi = eabi, gnu, android, macho, elf, etc.|}
      );
      ("-dump-llvm", Arg.Set dump_llvm, "Dump LLLVM IR");
    ]
  in
  let () = Arg.parse speclist anon_fun usage in

  if Array.length Sys.argv == 1 then (
    print_endline usage;
    exit 64);
  let target = match !target with "" -> None | s -> Some s in
  run_file (List.hd !filename) { target; dump_llvm = !dump_llvm }
