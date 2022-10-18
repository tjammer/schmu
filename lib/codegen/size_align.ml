open Cleaned_types

type size_pr = { size : int; align : int }

let alignup ~size ~upto =
  let modulo = size mod upto in
  if Int.equal modulo 0 then (* We are aligned *)
    size else size + (upto - modulo)

let add_size_align ~upto ~sz { size; align } =
  let size = alignup ~size ~upto + sz in
  let align = max align upto in
  { size; align }

(* Returns the size in bytes *)
let rec sizeof_typ typ =
  let rec inner size_pr typ =
    match typ with
    | Tint | Tfloat -> add_size_align ~upto:8 ~sz:8 size_pr
    | Ti32 | Tf32 -> add_size_align ~upto:4 ~sz:4 size_pr
    | Tbool | Tu8 ->
        (* No need to align one byte *)
        { size_pr with size = size_pr.size + 1 }
    | Tunit -> failwith "Does this make sense?"
    | Tfun _ ->
        (* Just a ptr? Or a closure, 2 ptrs. Assume 64bit *)
        add_size_align ~upto:8 ~sz:8 size_pr
    | Trecord (_, _, labels) ->
        let { size; align = upto } =
          Array.fold_left
            (fun pr (f : field) -> inner pr f.ftyp)
            { size = 0; align = 1 } labels
        in
        let sz = alignup ~size ~upto in
        add_size_align ~upto ~sz size_pr
    | Tvariant (_, _, ctors) ->
        (* For simplicity, we use i32 for the tag. If the variant contains no data
           i.e. is a C enum, we want to use i32 anyway, since that's what C uses.
           And then we don't have to worry about the size *)
        let init = inner { size = 0; align = 1 } Ti32 in
        let final =
          match variant_get_largest ctors with
          | Some typ -> inner init typ
          | None -> init
        in
        let sz = alignup ~size:final.size ~upto:final.align in
        add_size_align ~upto:final.align ~sz size_pr
    | Tpoly _ ->
        (* Llvm.dump_module the_module; *)
        failwith "too generic for a size"
    | Traw_ptr _ | Tarray _ ->
        (* TODO pass in triple. Until then, assume 64bit *)
        add_size_align ~upto:8 ~sz:8 size_pr
  in
  let { size; align = upto } = inner { size = 0; align = 1 } typ in
  alignup ~size ~upto

and variant_get_largest ctors =
  let largest, _ =
    Array.fold_left
      (fun (largest, size) ctor ->
        match ctor.ctyp with
        | None -> (largest, size)
        | Some typ ->
            let sz = sizeof_typ typ in
            if sz > size then (Some typ, sz) else (largest, size))
      (None, 0) ctors
  in
  largest