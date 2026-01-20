open Ast
module Sset = Set.Make (String)

let rec collect_deps ~modul set = function
  | Import id -> Sset.add (snd id) set
  | Ext_decl _ | Typedef _ | Module_alias _ | Signature _ | Stmt _
  | Module_type _ ->
      set
  | Module (_, prog) | Functor (_, _, prog) ->
      List.fold_left (collect_deps ~modul) set prog
  | Main (_, prog) ->
      if modul then set else List.fold_left (collect_deps ~modul) set prog

let print_deps ~modul ~outname prog =
  let set = List.fold_left (collect_deps ~modul) Sset.empty prog in
  let outputs =
    if modul then Format.sprintf "%s.o %s.smi" outname outname else outname
  in
  let deps =
    String.concat " "
      (Sset.to_seq set |> Seq.map (fun s -> s ^ ".smi") |> List.of_seq)
  in
  Format.printf "%s: %s@." outputs deps
