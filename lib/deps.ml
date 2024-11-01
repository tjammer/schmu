open Ast
module Sset = Set.Make (String)

let rec collect_deps set = function
  | Import id -> Sset.add (snd id) set
  | Ext_decl _ | Typedef _ | Module_alias _ | Signature _ | Stmt _
  | Module_type _ ->
      set
  | Module (_, prog) | Functor (_, _, prog) ->
      List.fold_left collect_deps set prog

let print_deps ~modul ~outname prog =
  let set = List.fold_left collect_deps Sset.empty prog in
  let outputs =
    if modul then Printf.sprintf "%s.o %s.smi" outname outname else outname
  in
  let deps =
    String.concat " "
      (Sset.to_seq set |> Seq.map (fun s -> s ^ ".smi") |> List.of_seq)
  in
  Printf.printf "%s: %s" outputs deps
