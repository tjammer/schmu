let prelude_obj () =
  (* If we made it to here, the prelude is found and available *)
  Filename.remove_extension (Option.get !Module.prelude_path) ^ ".o"

let link ~prelude outname modules cargs =
  (* Invoke 'cc' with all the files here *)
  let modules = if prelude then prelude_obj () :: modules else modules in
  let cmd =
    Printf.sprintf "cc -o %s %s.o %s" outname outname
      (String.concat " " (modules @ cargs))
  in
  let ret = Sys.command cmd in
  if ret = 0 then (* Remove temp object file *)
    Sys.remove (outname ^ ".o")
  else Printf.printf "cc returned %i: %s\n" ret cmd
