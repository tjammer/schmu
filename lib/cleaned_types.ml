type typ =
  | Tint
  | Tbool
  | Tunit
  | Tu8
  | Tu16
  | Tfloat
  | Ti32
  | Tf32
  | Tpoly of string
  | Tfun of param list * typ * fun_kind
  | Trecord of typ list * string option * field array
  | Tvariant of typ list * typ option * string * ctor array
  | Traw_ptr of typ
  | Tarray of typ
  | Tfixed_array of int * typ
  | Trc of typ
[@@deriving show { with_path = false }]

and fun_kind = Simple | Closure of closed list
and param = { pt : typ; pmut : bool; pmoved : bool }
and field = { ftyp : typ; mut : bool }
and ctor = { cname : string; ctyp : typ option; index : int }

and closed = {
  clname : string;
  clmut : bool;
  cltyp : typ;
  clparam : bool;
  clcopy : bool;
}

let is_type_polymorphic typ =
  let rec inner acc = function
    | Tpoly _ -> true
    | Trecord (_, None, fs) ->
        Array.fold_left (fun acc f -> inner acc f.ftyp) acc fs
    | Trecord (ps, _, _) | Tvariant (ps, _, _, _) -> List.fold_left inner acc ps
    | Tfun (params, ret, kind) ->
        let acc = List.fold_left (fun b p -> inner b p.pt) acc params in
        let acc =
          match kind with
          | Simple -> acc
          | Closure cls ->
              List.fold_left (fun acc cl -> inner acc cl.cltyp) acc cls
        in
        inner acc ret
    | Tbool | Tunit | Tint | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 -> acc
    | Tfixed_array (i, _) when i < 0 -> true
    | Traw_ptr t | Tarray t | Tfixed_array (_, t) | Trc t -> inner acc t
  in
  inner false typ

let rec string_of_type = function
  | Tint -> "int"
  | Tbool -> "bool"
  | Tunit -> "unit"
  | Tu8 -> "u8"
  | Tu16 -> "u16"
  | Tfloat -> "float"
  | Ti32 -> "i32"
  | Tf32 -> "f32"
  | Tfun (ts, t, _) ->
      let ps =
        String.concat " "
          (List.map
             (fun p -> string_of_type p.pt ^ if p.pmut then "&" else "")
             ts)
      in
      Printf.sprintf "(fun %s %s)" ps (string_of_type t)
  | Tpoly str -> str
  | Trecord (_, None, fs) ->
      let lst = Array.to_list fs |> List.map (fun f -> string_of_type f.ftyp) in
      Printf.sprintf "{%s}" (String.concat " " lst)
  | Trecord (ps, Some str, _) | Tvariant (ps, _, str, _) -> (
      match ps with
      | [] -> str
      | l ->
          let arg = String.concat " " (List.map string_of_type l) in
          Printf.sprintf "(%s %s)" str arg)
  | Traw_ptr t -> Printf.sprintf "(raw_ptr %s)" (string_of_type t)
  | Tarray t -> Printf.sprintf "(array %s)" (string_of_type t)
  | Tfixed_array (i, t) -> Printf.sprintf "(array#%i %s)" i (string_of_type t)
  | Trc t -> Printf.sprintf "(rc %s)" (string_of_type t)

let is_struct = function
  | Trecord _ | Tvariant _ | Tfun _ | Tpoly _ | Tfixed_array _ -> true
  | Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Traw_ptr _
  | Tarray _ | Trc _ ->
      false

let is_aggregate = function
  | Trecord _ | Tvariant _ | Tfixed_array _ -> true
  | Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Traw_ptr _
  | Tfun _ | Tpoly _ | Tarray _ | Trc _ ->
      false

let rec contains_allocation = function
  | Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 -> false
  | Tpoly _ | Tfun _ -> true
  | Trecord (_, _, fs) ->
      Array.fold_left (fun ca f -> ca || contains_allocation f.ftyp) false fs
  | Tvariant (_, _, _, ctors) ->
      Array.fold_left
        (fun ca c ->
          match c.ctyp with Some t -> ca || contains_allocation t | None -> ca)
        false ctors
  | Traw_ptr _ -> false
  | Tarray _ | Trc _ -> true
  | Tfixed_array (_, t) -> contains_allocation t

let folded typ =
  let rec aux isoid = function
    | Tvariant (_, Some (Tpoly id), _, _) when String.equal isoid id -> Tpoly id
    | Tvariant (ps, poly, name, ctors) ->
        let ps = List.map (aux isoid) ps in
        let ctors =
          Array.map
            (fun ct -> { ct with ctyp = Option.map (aux isoid) ct.ctyp })
            ctors
        in
        Tvariant (ps, poly, name, ctors)
    | Tfun (ps, r, kind) ->
        let ps = List.map (fun p -> { p with pt = aux isoid p.pt }) ps in
        let kind =
          match kind with
          | Simple -> Simple
          | Closure cls ->
              let cls =
                List.map
                  (fun cl -> { cl with cltyp = (aux isoid) cl.cltyp })
                  cls
              in
              Closure cls
        in
        Tfun (ps, aux isoid r, kind)
    | Trecord (ps, name, fields) ->
        let ps = List.map (aux isoid) ps in
        let fields =
          Array.map (fun f -> { f with ftyp = aux isoid f.ftyp }) fields
        in
        Trecord (ps, name, fields)
    | Traw_ptr t -> Traw_ptr ((aux isoid) t)
    | Tarray t -> Tarray (aux isoid t)
    | Trc t -> Trc (aux isoid t)
    | Tfixed_array (i, t) -> Tfixed_array (i, aux isoid t)
    | (Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Tpoly _) as t
      ->
        t
  in
  match typ with
  | Tvariant (ps, (Some (Tpoly id) as poly), name, ctors) ->
      let ps = List.map (aux id) ps in
      let ctors =
        Array.map
          (fun ct -> { ct with ctyp = Option.map (aux id) ct.ctyp })
          ctors
      in
      Tvariant (ps, poly, name, ctors)
  | t -> t

let unfolded typ =
  let rec unfold typ isoid = function
    | Tvariant (ps, poly, name, ctors) ->
        let ps = List.map (unfold typ isoid) ps in
        let ctors =
          Array.map
            (fun ct -> { ct with ctyp = Option.map (unfold typ isoid) ct.ctyp })
            ctors
        in
        Tvariant (ps, poly, name, ctors)
    | Tfun (ps, r, kind) ->
        let ps = List.map (fun p -> { p with pt = unfold typ isoid p.pt }) ps in
        let kind =
          match kind with
          | Simple -> Simple
          | Closure cls ->
              let cls =
                List.map
                  (fun cl -> { cl with cltyp = (unfold typ isoid) cl.cltyp })
                  cls
              in
              Closure cls
        in
        Tfun (ps, unfold typ isoid r, kind)
    | Trecord (ps, name, fields) ->
        let ps = List.map (unfold typ isoid) ps in
        let fields =
          Array.map (fun f -> { f with ftyp = unfold typ isoid f.ftyp }) fields
        in
        Trecord (ps, name, fields)
    | Traw_ptr t -> Traw_ptr ((unfold typ isoid) t)
    | Tarray t -> Tarray (unfold typ isoid t)
    | Trc t -> Trc (unfold typ isoid t)
    | Tfixed_array (i, t) -> Tfixed_array (i, unfold typ isoid t)
    | Tpoly id when String.equal id isoid -> typ
    | (Tint | Tbool | Tunit | Tu8 | Tu16 | Tfloat | Ti32 | Tf32 | Tpoly _) as t
      ->
        t
  in
  match folded typ with
  | Tvariant (ps, Some (Tpoly id), name, ctors) as t ->
      let ps = List.map (unfold t id) ps in
      let ctors =
        Array.map
          (fun ct -> { ct with ctyp = Option.map (unfold t id) ct.ctyp })
          ctors
      in
      Tvariant (ps, Some (Tpoly id), name, ctors)
  | t -> t
