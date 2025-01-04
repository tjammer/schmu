module Make (Mtree : Monomorph_tree_intf.S) = struct
  open Cleaned_types
  open Mtree
  open Malloc_types

  type malloc_scope = Mfunc | Mlocal

  let malloc_add_index index = function
    | Malloc.No_malloc -> Malloc.No_malloc
    | Path (m, p) -> Path (m, p @ [ index ])
    | (Single _ | Param _) as m -> Path (m, [ index ])

  let rec m_to_list = function
    | Malloc.No_malloc -> []
    | Single i -> [ i.mid ]
    | Param _ -> []
    | Path (m, [ -1 ]) ->
        (* Special case for rc/get *)
        m_to_list m
    | Path (m, -1 :: tl) -> m_to_list (Path (m, tl))
    | Path _ -> failwith "Internal Error: Path not supported here"

  type pmap = Pset.t Imap.t

  let rec is_arg = function
    | Malloc.No_malloc -> true
    | Param _ -> true
    | Single mid -> is_arg_mid mid
    | Path (m, _) -> is_arg m

  and is_arg_mid (mid : Mid.t) =
    match mid.parent with Some m -> is_arg m | None -> false

  let mlist_of_pmap m =
    Imap.to_rev_seq m
    |> Seq.filter_map (fun ((id : Mid.t), paths) ->
           (* If the malloc comes from a borrowed parameter, we don't add it to the
              list of mallocs. This list is later on used for freeing allocs. Since
              there are paths and parent relationsships, we need to recursively
              check if something is an argument. *)
           if is_arg_mid id then None
           else Some { id = id.mid; mtyp = id.typ; paths })
    |> List.of_seq

  let show_pmap m =
    Imap.to_seq m
    |> Seq.map (fun ((i : Mid.t), set) ->
           Printf.sprintf "%i: (%s)" i.mid (show_pset set))
    |> List.of_seq |> String.concat "\n"

  let mapdiff ?(flip = true) a b =
    ignore show_pmap;
    Imap.merge
      (fun _ a b ->
        match (a, b) with
        | Some a, Some b ->
            if Pset.is_empty b then None
            else
              (* The order here is switched, we want new moved things to appear *)
              let diff = if flip then Pset.diff b a else Pset.diff a b in
              if Pset.is_empty diff then None else Some diff
        | None, Some _ | None, None -> None
        | Some v, None -> Some v)
      a b

  let mapdiff_flip a b = mapdiff ~flip:false a b

  let mapunion a b =
    Imap.merge
      (fun _ a b ->
        match (a, b) with
        | Some a, Some b -> Some (Pset.union a b)
        | Some a, None -> Some a
        | None, Some b -> Some b
        | None, None -> None)
      a b

  let mk_free_after expr frees =
    (* Delete paths if all allocating members are excluded *)
    let rec is_excluded frees typ =
      if Pset.is_empty frees then (false, frees)
      else
        match typ with
        | Trecord (_, (Rec_not fs | Rec_top fs), _) ->
            let _, excluded, pset =
              Array.fold_left
                (fun (i, exh, pset) f ->
                  if contains_allocation f.ftyp then
                    match pop_index_pset frees i with
                    | Not_excl -> (i + 1, false, pset)
                    | Excl -> (i + 1, exh && true, Pset.add [ i ] pset)
                    | Followup frees ->
                        let nexcluded, npset = is_excluded frees f.ftyp in
                        let npset =
                          if nexcluded then pset
                          else Pset.map (fun l -> i :: l) npset
                        in
                        (i + 1, exh && nexcluded, npset)
                  else (i + 1, exh, pset))
                (0, true, Pset.empty) fs
            in
            (excluded, pset)
        | Trc (Strong, t) ->
            if contains_allocation t then
              match pop_index_pset frees (-1) with
              | Not_excl -> (false, Pset.empty)
              | Excl -> (false, Pset.singleton [ -1 ])
              | Followup frees ->
                  let nexcluded, npset = is_excluded frees t in
                  let npset =
                    if nexcluded then Pset.empty
                    else Pset.map (fun l -> -1 :: l) npset
                  in
                  (nexcluded, npset)
            else (true, Pset.empty)
        | _ -> failwith "todo exh"
    in
    let frees =
      List.filter_map
        (fun free ->
          let excluded, paths = is_excluded free.paths free.mtyp in
          if excluded then None else Some { free with paths })
        frees
    in
    match frees with
    | [] -> expr
    | frees -> { expr with expr = Mfree_after (expr, Except frees) }

  module Mallocs : sig
    type t

    val show : t -> string
    val empty : malloc_scope -> t
    val push : malloc_scope -> t -> t
    val pop : t -> malloc_id list * t
    val find : Malloc.t -> t -> pset Imap.t option
    val add : Malloc.t -> t -> t
    val remove : Malloc.t -> t -> t
    val reenter : Malloc.t -> t -> t
    val remove_local : Malloc.t -> t -> t
    val empty_func : monod_tree -> t -> t * monod_tree
    val diff_func : t -> t -> Pset.t Imap.t
  end = struct
    open Malloc

    type t = (malloc_scope * pmap) list

    let show t =
      "["
      ^ String.concat "\n::\n"
          (List.map
             (fun (scope, pmap) ->
               match scope with
               | Mfunc -> "Mfunc"
               | Mlocal ->
                   "Mlocal"
                   ^ (Imap.to_seq pmap
                     |> Seq.map (fun (mid, set) ->
                            Mid.show mid ^ ": {"
                            ^ (Pset.to_seq set |> Seq.map Mpath.show
                             |> List.of_seq |> String.concat " and ")
                            ^ "}")
                     |> List.of_seq |> String.concat "\n"))
             t)
      ^ "]"

    let empty scope = [ (scope, Imap.empty) ]
    let push kind ms = (kind, Imap.empty) :: ms
    let pop = function (_, ms) :: tl -> (mlist_of_pmap ms, tl) | [] -> ([], [])

    let find a ms =
      let rec aux a ms path =
        match (a, ms) with
        | _, [] -> None
        | (Single i | Param i), (_, ms) :: tl ->
            let mem =
              match Imap.find_opt i ms with
              | Some pset -> (
                  match path with
                  | [] -> Some (Imap.add i pset Imap.empty)
                  | path ->
                      if Pset.mem path pset then None
                      else Some (Imap.add i pset Imap.empty))
              | None -> None
            in
            if Option.is_some mem then mem else aux a tl path
        | No_malloc, _ -> None
        | Path (a, l), _ ->
            print_endline ("it's a path: " ^ Mpath.show l);
            (* Order of appending paths is important *)
            aux a ms (l @ path)
      in
      aux a ms []

    let mem a ms =
      let rec aux a ms path =
        match (a, ms) with
        | _, [] -> false
        | (Single i | Param i), (_, ms) :: tl ->
            let mem =
              match Imap.find_opt i ms with
              | Some pset -> (
                  match path with
                  | [] -> true
                  | path -> Pset.mem path pset |> not)
              | None -> false
            in
            mem || aux a tl path
        | No_malloc, _ -> false
        | Path (a, l), _ ->
            (* Order of appending paths is important *)
            aux a ms (l @ path)
      in
      aux a ms []

    let add a ms =
      match (a, ms) with
      | _, [] -> failwith "Internal Error: Empty ids"
      | (Single a | Param a), (scope, ms) :: tl ->
          (scope, Imap.add a Pset.empty ms) :: tl
      | No_malloc, _ -> ms
      | Path _, _ -> failwith "Internal Error: Trying to add pathed malloc"

    let reenter a ms =
      let rec aux a ms =
        match (a, ms) with
        | _, [] -> []
        | (Param a as mlc), (Mlocal, ms) :: tl ->
            (* If we reenter a parent, delete moved children from map *)
            let ms =
              Imap.filter_map
                (fun mid thing ->
                  match mid.parent with
                  | Some p -> (
                      match mid_of_malloc p with
                      | Some p when Mid.compare p a = 0 -> None
                      | Some _ | None -> Some thing)
                  | None -> Some thing)
                ms
            in

            (Mlocal, ms) :: aux mlc tl
        | Param a, (Mfunc, ms) :: tl -> (Mfunc, Imap.add a Pset.empty ms) :: tl
        | Single a, (scope, ms) :: tl -> (scope, Imap.add a Pset.empty ms) :: tl
        | No_malloc, _ -> ms
        | Path ((Single i | Param i), p), (scope, ms) :: tl ->
            let found, ms =
              match Imap.find_opt i ms with
              | Some pset -> (true, Imap.add i (Pset.remove p pset) ms)
              | None -> (false, ms)
            in
            if found then (scope, ms) :: tl else (scope, ms) :: aux a tl
        | Path _, _ -> failwith "Internal Error: Unexpected path"
      in
      aux a ms

    let remove a ms =
      let rec aux a path ms =
        match (a, ms) with
        | _, [] -> []
        | Single { parent = Some par; _ }, _
        | Param { parent = Some par; _ }, _
          when (not (mem par ms)) && not (mem a ms) ->
            (* Except when it has a parent and the parent is still part of the
               tail. Then it's about to be removed and the child part has to be
               added here. *)
            aux a path (add a ms)
        | (Single i | Param i), (scope, ms) :: tl ->
            let ms =
              match path with
              | [] -> Imap.remove i ms
              | p -> (
                  match Imap.find_opt i ms with
                  | Some pset ->
                      (* Malloc id was found, mark path as moved in set *)
                      Imap.add i (Pset.add p pset) ms
                  | None ->
                      (* Malloc id isn't part of this scope, do nothing *)
                      ms)
            in
            (* If the malloc has a parent, it's a variant. The variant must be
               removed as a whole from the tail *)
            let tl =
              match i.parent with Some par -> aux par [] tl | None -> tl
            in
            (scope, ms) :: aux a path tl
        | No_malloc, _ -> ms
        | Path (a, l), _ -> aux a (l @ path) ms
      in
      aux a [] ms

    let remove_local a ms =
      let rec aux a path ms =
        match (a, ms) with
        | _, [] -> []
        | Single ({ parent = Some par; _ } as i), (_, ms') :: _
        | Param ({ parent = Some par; _ } as i), (_, ms') :: _
          when (not (mem par ms)) && not (Imap.mem i ms') ->
            (* Except when it has a parent and the parent is still part of the
               tail. Then it's about to be removed and the child part has to be
               added here. *)
            aux a path (add a ms)
        | (Single i | Param i), (scope, ms) :: tl ->
            let ms =
              match path with
              | [] -> Imap.remove i ms
              | p -> (
                  match Imap.find_opt i ms with
                  | Some pset -> Imap.add i (Pset.add p pset) ms
                  | None -> ms)
            in
            let tl =
              match i.parent with Some par -> aux par [] tl | None -> tl
            in
            (scope, ms) :: tl
        | No_malloc, _ -> ms
        | Path (a, l), _ -> aux a (l @ path) ms
      in
      aux a [] ms

    let rec empty_func body = function
      | [] -> ([], body)
      | (Mlocal, s) :: tl ->
          let frees = mlist_of_pmap s in
          let tl, body = empty_func (mk_free_after body frees) tl in
          ((Mlocal, Imap.empty) :: tl, body)
      | (Mfunc, s) :: tl ->
          let frees = mlist_of_pmap s in
          ((Mfunc, Imap.empty) :: tl, mk_free_after body frees)

    let diff_func a b =
      (* TODO take paths into account *)
      let rec aux acc a b =
        match (a, b) with
        | (Mlocal, a) :: atl, (Mlocal, b) :: btl ->
            aux (mapunion acc (mapdiff a b)) atl btl
        | (Mfunc, a) :: _, (Mfunc, b) :: _ -> mapunion acc (mapdiff a b)
        | _ -> failwith "Internal Error: Mismatch in scope"
      in
      aux Imap.empty a b
  end
end
