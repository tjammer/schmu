let link outname modules cargs =
  (* Invoke 'cc' with all the files here *)
  let cmd =
    Printf.sprintf "cc -o %s %s.o %s" outname outname
      (String.concat " " (modules @ cargs))
  in
  let ret = Sys.command cmd in
  if ret = 0 then (* Remove temp object file *)
    Sys.remove (outname ^ ".o")
  else Printf.printf "cc returned %i: %s\n" ret cmd
