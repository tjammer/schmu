type opts = {
  target : string option;
  outname : string;
  dump_llvm : bool;
  release : bool;
  modul : bool;
  compile_only : bool;
  no_prelude : bool;
  objects : string list;
  check_only : bool;
  cargs : string list;
}

let ( >>= ) = Result.bind

let prelude_paths opts =
  (* In case we find nothing, we append the empty list *)
  if opts.no_prelude then []
  else
    let ( // ) = Filename.concat in
    let file =
      match Schmu_std.Sites.std with
      | file :: _ -> file
      | [] ->
          (Sys.argv.(0) |> Filename.dirname)
          // ".." // "lib" // "schmu" // "std"
    in
    if Sys.file_exists (file // "prelude.smu") then [ file ] else []

let run file
    {
      target;
      outname;
      dump_llvm;
      release;
      modul;
      compile_only;
      no_prelude;
      objects;
      check_only;
      cargs;
    } =
  let fmt_msg_fn kind loc msg =
    let file = Lexing.((fst loc).pos_fname) in
    let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
    let errloc = fst loc in
    let loc = Pp_loc.Position.(of_lexing (fst loc), of_lexing (snd loc)) in

    Format.asprintf "%s:%d:%d: %s: %s\n%!%a" file errloc.pos_lnum
      (errloc.pos_cnum - errloc.pos_bol + 1)
      kind msg pp [ loc ]
  in

  let prelude = not no_prelude in
  let open Schmulang in
  try
    Parse.parse file >>= fun prog ->
    Ok
      (let ttree, m = Typing.to_typed ~modul ~prelude fmt_msg_fn prog in

       let md = if modul then Some outname else None in

       if check_only then ()
       else (
         (* TODO if a module has only forward decls, we don't need to codegen anything *)
         Monomorph_tree.monomorphize ttree
         |> Codegen.generate ~target ~outname ~release ~modul:md
         |> ignore;
         if dump_llvm then Llvm.dump_module Codegen.the_module;
         if modul then (
           let modfile = open_out (outname ^ ".smi") in
           let prefix =
             if no_prelude && String.equal outname "prelude" then "schmu"
             else outname
           in
           Module.to_channel modfile prefix (Option.get m);
           close_out modfile)
         else if compile_only then ()
         else Link.link outname objects cargs))
  with Typed_tree.Error (loc, msg) -> Error (fmt_msg_fn "error" loc msg)

let run_file filename opts =
  (* Add sites to module search path *)
  Schmulang.Module.paths := prelude_paths opts @ !Schmulang.Module.paths;

  match run filename opts with
  | Ok () -> ()
  | Error msg ->
      prerr_endline msg;
      exit 1

let default_outname filename = Filename.(basename filename |> remove_extension)
let usage = "Usage: schmu [options] filename"

let () =
  (* Leave this in for debugging *)
  let () = Printexc.record_backtrace true in
  let target = ref "" in
  let dump_llvm = ref false in
  let outname = ref "" in
  let filename = ref None in
  let objects = ref [] in
  let release = ref false in
  let modul = ref false in
  let compile_only = ref false in
  let no_prelude = ref false in
  let check_only = ref false in
  let cargs = ref [] in
  let carg s = cargs := s :: !cargs in
  let anon_fun fn =
    if Filename.check_suffix fn ".o" then objects := fn :: !objects
    else if Filename.check_suffix fn ".smu" then (
      match !filename with
      | None -> filename := Some fn
      | Some _ ->
          (* We only allow a single filename (for now) *)
          print_endline usage;
          exit 64)
    else (
      print_endline @@ "Don't know what to do with suffix "
      ^ Filename.extension fn;
      exit 64)
  in
  let speclist =
    [
      ("-o", Arg.Set_string outname, "Place the output into given file");
      ( "--target",
        Arg.Set_string target,
        {|triple
    The triple has the general format <arch><sub>-<vendor>-<sys>-<abi>, where:
            arch = x86_64, i386, arm, thumb, mips, etc.
            sub = for ex. on ARM: v5, v6m, v7a, v7m, etc.
            vendor = pc, apple, nvidia, ibm, etc.
            sys = none, linux, win32, darwin, cuda, etc.
            abi = eabi, gnu, android, macho, elf, etc.|}
      );
      ("--dump-llvm", Arg.Set dump_llvm, "Dump LLLVM IR");
      ("--release", Arg.Set release, "Optimize");
      ("-m", Arg.Set modul, "Compile module");
      ("-c", Arg.Set compile_only, "Compile as main, but don't link");
      ("--no-prelude", Arg.Set no_prelude, "Compile without prelude");
      ("--check", Arg.Set check_only, "Typecheck only");
      ("--cc", Arg.String carg, "Pass to C compiler");
    ]
  in
  let () = Arg.parse speclist anon_fun usage in

  if Array.length Sys.argv = 1 then (
    print_endline usage;
    exit 64);
  let target = match !target with "" -> None | s -> Some s in
  (match !filename with
  | None ->
      print_endline "No main module";
      exit 64
  | Some _ -> ());
  let outname =
    match !outname with
    | "" -> default_outname (Option.get !filename)
    | s ->
        if Filename.check_suffix s ".o" then Filename.chop_suffix s ".o" else s
  in
  run_file (Option.get !filename)
    {
      target;
      outname;
      dump_llvm = !dump_llvm;
      release = !release;
      modul = !modul;
      compile_only = !compile_only;
      no_prelude = !no_prelude;
      objects = List.rev !objects;
      check_only = !check_only;
      cargs = List.rev !cargs;
    }
