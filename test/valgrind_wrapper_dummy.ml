let len = Array.length Sys.argv

let rec find_first_positional_argument i =
  if i = len then None
  else
    let arg = Array.get Sys.argv i in
    if String.starts_with ~prefix:"-" arg then
      find_first_positional_argument (i + 1)
    else Some i

let () =
  match find_first_positional_argument 1 with
  | Some i ->
      let cmd =
        Array.sub Sys.argv i (len - i) |> Array.to_list |> String.concat " "
      in
      let ic = Unix.open_process_in cmd in
      print_string (In_channel.input_all ic)
  | None -> prerr_endline "could not find positional argument"
