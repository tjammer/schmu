let link outname objects cargs =
  (* Invoke 'cc' with all the files here *)
  let objects = objects @ Module.object_names () in
  let cc =
    match Sys.getenv_opt "CC" with
    | None -> "cc"
    | Some path -> if String.length path <> 0 then path else "cc"
  in
  let cmd =
    Printf.sprintf "%s -o %s %s %s.o %s" cc outname
      (String.concat " " objects)
      outname (String.concat " " cargs)
  in
  let ret = Sys.command cmd in
  if ret = 0 then (
    (* Remove temp object file *)
    Sys.remove (outname ^ ".o");
    Ok ())
  else Error (Printf.sprintf "cc returned %i: %s\n" ret cmd)
