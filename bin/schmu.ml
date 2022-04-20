open Lexing

type opts = { target : string option; outname : string; dump_llvm : bool }

let pp_position lexbuf file =
  let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
  let pos = lexbuf.lex_curr_p in
  let pos =
    Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)
  in
  (pp, pos)

let run file src { target; outname; dump_llvm } =
  let fmt_msg_fn kind loc msg =
    let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
    let errloc = fst loc in
    Format.asprintf "%s:%d:%d: %s: %s\n%!%a" file errloc.pos_lnum
      (errloc.pos_cnum - errloc.pos_bol + 1)
      kind msg pp [ loc ]
  in

  let lexbuf = Lexing.from_string src in
  Schmulang.(
    try
      let prog = Parser.prog Lexer.read lexbuf in
      Ok
        (let tree =
           Typing.to_typed fmt_msg_fn prog |> Monomorph_tree.monomorphize
         in
         ignore (Codegen.generate ~target ~outname tree);
         if dump_llvm then Llvm.dump_module Codegen.the_module)
    with
    | Lexer.SyntaxError msg ->
        let loc = (lexbuf.lex_start_p, lexbuf.lex_curr_p) in
        let pp, pos = pp_position lexbuf file in
        Error (Format.asprintf "%s:%s %s\n%!%a" file pos msg pp [ loc ])
    | Parser.Error ->
        let loc = (lexbuf.lex_start_p, lexbuf.lex_curr_p) in
        let pp, pos = pp_position lexbuf file in
        Error
          (Format.asprintf "%s:%s %s\n%!%a" file pos "syntax error" pp [ loc ])
    | Typing.Error (loc, msg) -> Error (fmt_msg_fn "error" loc msg))

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
  (* Leave this in for debugging *)
  (* let () = Printexc.record_backtrace true in *)
  let target = ref "" in
  let dump_llvm = ref false in
  let outname = ref "" in
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
      ("-o", Arg.Set_string outname, "Place the output into given file");
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
  let outname = match !outname with "" -> "out.o" | s -> s in
  run_file (List.hd !filename) { target; outname; dump_llvm = !dump_llvm }
