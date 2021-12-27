module PolyMap : sig
  type 'a t

  type location = { name : string; lvl : int }

  val find_opt : string -> 'a t -> ('a Lazy.t * location) option

  val add_single : string -> (unit -> 'a) -> 'a t -> 'a t

  val add_container : string list -> (unit -> 'a) -> 'a t -> 'a t

  val to_args : 'a t -> string Seq.t

  val empty : 'a t
end = struct
  module M = Map.Make (String)

  type 'a lvl_cont = { value : 'a Lazy.t; name : string; lvl : int }

  type location = { name : string; lvl : int }

  type 'a t = 'a lvl_cont M.t

  let find_opt key m =
    match M.find_opt key m with
    | Some { value; name; lvl } -> Some (value, { name; lvl })
    | None -> None

  let add_single_lvl name container fvalue lvl m =
    match M.find_opt name m with
    | Some { value = _; lvl = l; name = _ } when l > lvl ->
        (* Smaller level -> In some hierarchy *)
        m
    | None | Some _ ->
        let value = Lazy.from_fun fvalue in
        M.add name { value; name = container; lvl } m

  let add_single key value m = add_single_lvl key key value 0 m

  let add_container keys value m =
    let container = List.hd keys in
    List.fold_left
      (fun (m, lvl) key -> (add_single_lvl key container value lvl m, lvl + 1))
      (m, 0) keys
    |> fst

  let to_args m =
      M.to_seq m
      |> Seq.filter_map (fun (key, { value = _ ;name; lvl }) ->
             if lvl = 0 then (
               assert (String.equal name key);
               Some key)
             else None)

  let empty = M.empty
end

module PolyLvls : sig
  type t

  type location = { name : string; lvl : int }

  val find_opt : string -> t -> location option

  val add_single : string -> t -> t

  val add_container : string list -> t -> t

  val to_params : t -> string Seq.t
  (* Produces the polymorphic parameters *)

  val fold : (string -> location list -> 'a -> 'a) -> t -> 'a -> 'a
  (* Folds over the parameters and their content *)

  val empty : t
end = struct
  module M = Map.Make (String)

  type location = { name : string; lvl : int }

  type t = location M.t

  let find_opt key m = M.find_opt key m

  let add_single_lvl name container lvl m =
    match M.find_opt name m with
    | Some l when l.lvl > lvl -> m
    | None | Some _ -> M.add name { name = container; lvl } m

  let add_single key m = add_single_lvl key key 0 m

  let add_container keys m =
    let container = List.hd keys in
    List.fold_left
      (fun (m, lvl) key -> (add_single_lvl key container lvl m, lvl + 1))
      (m, 0) keys
    |> fst

  let to_params m =
    let s =
      M.to_seq m
      |> Seq.filter_map (fun (key, { name; lvl }) ->
             if lvl = 0 then (
               assert (String.equal name key);
               Some key)
             else None)
    in
    print_endline (String.concat " -> " (List.of_seq s));
    s

  let sort_into_params m =
    let f key { name; lvl } m =
      M.update name
        (function
          | Some lst -> Some ({ name = key; lvl } :: lst)
          | None -> Some [ { name = key; lvl } ])
        m
    in
    M.fold f m M.empty

  let fold f m init =
    let m = sort_into_params m in
    M.fold (fun pvar _ acc -> pvar :: acc) m []
    |> List.rev |> String.concat " -> " |> print_endline;
    M.fold f m init

  let empty = M.empty
end
