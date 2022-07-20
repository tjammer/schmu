type opts = {
  target : string option;
  outname : string;
  dump_llvm : bool;
  release : bool;
  modul : bool;
  compile_only : bool;
  no_prelude : bool;
  link_modules : string list;
}

let ( >>= ) = Result.bind

let read_prelude opts =
  if opts.no_prelude then Ok ""
  else
    let ( // ) = Filename.concat in
    let file =
      match Schmu_std.Sites.std with
      | file :: _ -> file // "prelude.smu"
      | [] ->
          (Sys.argv.(0) |> Filename.dirname)
          // ".." // "lib" // "schmu" // "std" // "prelude.smu"
    in
    if Sys.file_exists file then Ok file
    else Error ("Could not open prelude at " ^ file)

let run file prelude
    {
      target;
      outname;
      dump_llvm;
      release;
      modul;
      compile_only;
      no_prelude;
      link_modules;
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

  let open Schmulang in
  try
    (if no_prelude then Ok [] else Parse.parse prelude) >>= fun prelude ->
    Parse.parse file >>= fun prog ->
    Ok
      (let ttree, m = Typing.to_typed ~modul ~prelude fmt_msg_fn prog in

       (* TODO if a module has only forward decls, we don't need to codegen anything *)
       Monomorph_tree.monomorphize ttree
       |> Codegen.generate ~target ~outname ~release ~modul
       |> ignore;
       if dump_llvm then Llvm.dump_module Codegen.the_module;
       if modul then (
         let m = Option.get m |> List.rev |> Module.sexp_of_t in
         let modfile = open_out (outname ^ ".smi") in
         Module.Sexp.to_channel modfile m;
         close_out modfile)
       else if compile_only then ()
       else Link.link outname link_modules)
  with Typed_tree.Error (loc, msg) -> Error (fmt_msg_fn "error" loc msg)

let run_file filename opts =
  (* Open the prelude *)
  (read_prelude opts >>= fun prelude -> run filename prelude opts) |> function
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
  let link_modules = ref [] in
  let release = ref false in
  let modul = ref false in
  let compile_only = ref false in
  let no_prelude = ref false in
  let anon_fun fn =
    if Filename.check_suffix fn ".o" then link_modules := fn :: !link_modules
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
      link_modules = List.rev !link_modules;
    }
