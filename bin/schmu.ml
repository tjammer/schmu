type opts = {
  target : string option;
  outname : string;
  dump_llvm : bool;
  release : bool;
  modul : bool;
  compile_only : bool;
  no_std : bool;
  objects : string list;
  check_only : bool;
  cargs : string list;
  search_paths : string list;
  deps : bool;
}

let ( >>= ) = Result.bind

let std_paths opts =
  (* In case we find nothing, we append the empty list *)
  if opts.no_std then []
  else
    let ( // ) = Filename.concat in
    let file =
      match Schmu_std.Sites.std with
      | file :: _ -> file
      | [] ->
          (Sys.argv.(0) |> Filename.dirname)
          // ".." // "lib" // "schmu" // "std"
    in
    if Sys.file_exists (file // "std.smu") then [ file ] else []

let run file
    {
      target;
      outname;
      dump_llvm;
      release;
      modul;
      compile_only;
      no_std;
      objects;
      check_only;
      cargs;
      search_paths = _;
      deps;
    } =
  let fmt_msg_fn kind loc msg =
    let file = Lexing.((fst loc).pos_fname) in
    let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
    let beg = fst loc in
    let nnd = snd loc in
    let loc = Pp_loc.Position.(of_lexing (fst loc), of_lexing (snd loc)) in

    let cbeg = beg.pos_cnum - beg.pos_bol + 1
    and cend = nnd.pos_cnum - nnd.pos_bol + 1 in
    if Int.equal beg.pos_lnum nnd.pos_lnum then
      (* Fits on one line *)
      Format.asprintf "%s:%d.%d-%d: %s: %s.\n\n%!%a" file beg.pos_lnum cbeg cend
        kind msg pp [ loc ]
    else
      (* Spans multiple lines *)
      Format.asprintf "%s:%d.%d-%d.%d: %s: %s.\n\n%!%a" file beg.pos_lnum cbeg
        nnd.pos_lnum cend kind msg pp [ loc ]
  in

  let std = not no_std in
  let open Schmulang in
  try
    Parse.parse file >>= fun prog ->
    let mname = if modul then Path.Pid outname else Typing.main_path in
    let start_loc =
      let loc =
        Lexing.{ pos_fname = file; pos_lnum = 1; pos_bol = 1; pos_cnum = 1 }
      in
      (loc, loc)
    in
    if deps then (
      Deps.print_deps ~modul ~outname prog;
      Ok ())
    else
      let ttree, m = Typing.to_typed ~mname ~std ~start_loc fmt_msg_fn prog in

      if check_only then Ok ()
      else
        (* TODO if a module has only forward decls, we don't need to codegen anything *)
        let args = if modul then false else Module.uses_args () in
        Monomorph_tree.monomorphize ~mname ttree
        |> Codegen.generate ~target ~outname ~release ~modul ~args ~start_loc
        |> ignore;
        if dump_llvm then Llvm.dump_module Codegen.the_module;
        if modul then (
          let modfile = open_out (outname ^ ".smi") in
          Module.to_channel modfile ~outname m;
          close_out modfile;
          Ok ())
        else if compile_only then Ok ()
        else Link.link outname objects cargs
  with Error.Error (loc, msg) -> Error (fmt_msg_fn "error" loc msg)

let run_file filename opts =
  (* Add sites to module search path *)
  Schmulang.Module.paths :=
    std_paths opts @ !Schmulang.Module.paths @ opts.search_paths;

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
  let no_std = ref false in
  let check_only = ref false in
  let cargs = ref [] in
  let deps = ref false in
  let carg s = cargs := s :: !cargs in
  let search_paths = ref [] in
  let search_path s = search_paths := s :: !search_paths in
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
      ("-s", Arg.String search_path, "Additional module search path");
      ("--no-std", Arg.Set no_std, "Compile without std library");
      ("--check", Arg.Set check_only, "Typecheck only");
      ("--cc", Arg.String carg, "Pass to C compiler");
      ("--deps", Arg.Set deps, "Print module dependencies");
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
      no_std = !no_std;
      objects = List.rev !objects;
      check_only = !check_only;
      cargs = List.rev !cargs;
      search_paths = List.rev !search_paths;
      deps = !deps;
    }
