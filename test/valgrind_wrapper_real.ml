let () =
  let _pid = Unix.(create_process "valgrind" Sys.argv stdin stdout stderr) in
  Unix.waitpid [] 0 |> ignore
