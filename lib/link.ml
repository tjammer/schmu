let prelude_obj () =
  (* If we made it to here, the prelude is found and available *)
  Filename.remove_extension (Option.get !Module.prelude_path) ^ ".o"

let link ~prelude outname objects cargs =
  (* Invoke 'cc' with all the files here *)
  let modules =
    Hashtbl.fold
      (fun name _ l ->
        match name with
        | "prelude" -> l
        | name ->
            let f = Module.find_file name ".o" in
            f :: l)
      Module.module_cache objects
  in
  let objects = if prelude then prelude_obj () :: modules else modules in
  let cmd =
    Printf.sprintf "cc -o %s %s.o %s" outname outname
      (String.concat " " (objects @ cargs))
  in
  let ret = Sys.command cmd in
  if ret = 0 then (* Remove temp object file *)
    Sys.remove (outname ^ ".o")
  else Printf.printf "cc returned %i: %s\n" ret cmd
