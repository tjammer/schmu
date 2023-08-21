let link outname objects cargs =
  (* Invoke 'cc' with all the files here *)
  let objects = objects @ Module.object_names () in
  let cmd =
    Printf.sprintf "cc -o %s %s %s.o" outname
      (String.concat " " (objects @ cargs))
      outname
  in
  let ret = Sys.command cmd in
  if ret = 0 then (* Remove temp object file *)
    Sys.remove (outname ^ ".o")
  else Printf.printf "cc returned %i: %s\n" ret cmd
