type t =
  | Unsafe_ptr_get
  | Unsafe_ptr_set
  | Unsafe_ptr_at
  | Unsafe_ptr_reinterpret
  | Unsafe_addr
  | Ignore
  | Cast of Types.typ * Types.typ
  | Not
  | Mod
  | Array_get
  | Array_length
  | Unsafe_array_pop_back
  | Array_data
  | Array_capacity
  | Fixed_array_get
  | Fixed_array_length
  | Fixed_array_data
  | Unsafe_array_realloc
  | Unsafe_array_create
  | Unsafe_array_length
  | Unsafe_nullptr
  | Unsafe_funptr
  | Unsafe_clsptr
  | Unsafe_leak
  | Unsafe_unchecked
  | Is_nullptr
  | Assert
  | Copy
  | Land
  | Lor
  | Lxor
  | Lshl
  | Lshr
  | Ashr
  | Addi
  | Subi
  | Multi
  | Divi
  | Diviu
  | Addf
  | Subf
  | Mulf
  | Divf
  | Lessi
  | Greateri
  | Lesseqi
  | Greatereqi
  | Lessiu
  | Greateriu
  | Lesseqiu
  | Greatereqiu
  | Equali
  | Nequali
  | Lessf
  | Greaterf
  | Lesseqf
  | Greatereqf
  | Equalf
  | Nequalf
  | Rc_create
  | Unsafe_rc_get
  | Rc_to_weak
  | Unsafe_rc_of_weak
  | Rc_cnt
  | Rc_wcnt
  | Any_abort
  | Any_exit
[@@deriving show]

let tbl =
  let open Types in
  let po = { Types.pattr = Dnorm; pt = tunit; pmode = ref (Iknown Once) } in
  let pm = { Types.pattr = Dnorm; pt = tunit; pmode = ref (Iknown Many) } in
  let tbl = Hashtbl.create 64 in

  Hashtbl.add tbl "__unsafe_ptr_get"
    ( Unsafe_ptr_get,
      Types.Tfun
        ( [ { pm with pt = traw_ptr (Qvar "0") }; { pm with pt = tint } ],
          Qvar "0",
          Simple ) );
  Hashtbl.add tbl "__unsafe_ptr_set"
    ( Unsafe_ptr_set,
      Tfun
        ( [
            { pm with pt = traw_ptr (Qvar "0"); pattr = Dmut };
            { pm with pt = tint };
            { pm with pt = Qvar "0"; pattr = Dmove };
          ],
          tunit,
          Simple ) );
  Hashtbl.add tbl "__unsafe_ptr_at"
    ( Unsafe_ptr_at,
      Tfun
        ( [ { pm with pt = traw_ptr (Qvar "0") }; { pm with pt = tint } ],
          traw_ptr (Qvar "0"),
          Simple ) );
  Hashtbl.add tbl "__unsafe_ptr_reinterpret"
    ( Unsafe_ptr_reinterpret,
      Tfun
        ([ { pm with pt = traw_ptr (Qvar "0") } ], traw_ptr (Qvar "1"), Simple)
    );
  Hashtbl.add tbl "__unsafe_addr"
    ( Unsafe_addr,
      Tfun
        ( [ { pm with pt = Qvar "0"; pattr = Dmut } ],
          traw_ptr (Qvar "0"),
          Simple ) );
  Hashtbl.add tbl "ignore"
    (Ignore, Tfun ([ { pm with pt = Qvar "0" } ], tunit, Simple));
  Hashtbl.add tbl "__ignore_once"
    (Ignore, Tfun ([ { po with pt = Qvar "0" } ], tunit, Simple));
  Hashtbl.add tbl "not" (Not, Tfun ([ { pm with pt = tbool } ], tbool, Simple));
  Hashtbl.add tbl "mod"
    (Mod, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__array_get"
    ( Array_get,
      Tfun
        ( [ { pm with pt = tarray (Qvar "0") }; { pm with pt = tint } ],
          Qvar "0",
          Simple ) );
  Hashtbl.add tbl "__array_length"
    (Array_length, Tfun ([ { pm with pt = tarray (Qvar "0") } ], tint, Simple));
  Hashtbl.add tbl "__unsafe_array_pop_back"
    ( Unsafe_array_pop_back,
      Tfun
        ([ { pm with pt = tarray (Qvar "0"); pattr = Dmut } ], Qvar "0", Simple)
    );
  Hashtbl.add tbl "__array_data"
    ( Array_data,
      Tfun ([ { pm with pt = tarray (Qvar "0") } ], traw_ptr (Qvar "0"), Simple)
    );
  Hashtbl.add tbl "__array_capacity"
    (Array_capacity, Tfun ([ { pm with pt = tarray (Qvar "0") } ], tint, Simple));
  Hashtbl.add tbl "__fixed_array_get"
    ( Fixed_array_get,
      Tfun
        ( [
            { pm with pt = Tfixed_array (ref (Types.Generalized "0"), Qvar "0") };
            { pm with pt = tint };
          ],
          Qvar "0",
          Simple ) );
  Hashtbl.add tbl "__fixed_array_length"
    ( Fixed_array_length,
      Tfun
        ( [
            { pm with pt = Tfixed_array (ref (Types.Generalized "0"), Qvar "0") };
          ],
          tint,
          Simple ) );
  Hashtbl.add tbl "__fixed_array_data"
    ( Fixed_array_data,
      Tfun
        ( [
            { pm with pt = Tfixed_array (ref (Types.Generalized "0"), Qvar "0") };
          ],
          traw_ptr (Qvar "0"),
          Simple ) );
  Hashtbl.add tbl "__unsafe_array_realloc"
    ( Unsafe_array_realloc,
      Tfun
        ( [
            { pm with pt = tarray (Qvar "0"); pattr = Dmut };
            { pm with pt = tint };
          ],
          tunit,
          Simple ) );
  Hashtbl.add tbl "__unsafe_array_create"
    ( Unsafe_array_create,
      Tfun ([ { pm with pt = tint } ], tarray (Qvar "0"), Simple) );
  Hashtbl.add tbl "__unsafe_array_length"
    ( Unsafe_array_length,
      Tfun ([ { pm with pt = tarray (Qvar "0") } ], tint, Simple) );
  Hashtbl.add tbl "__unsafe_nullptr"
    (Unsafe_nullptr, Tfun ([], traw_ptr tu8, Simple));
  Hashtbl.add tbl "__unsafe_funptr"
    (Unsafe_funptr, Tfun ([ { pm with pt = Qvar "0" } ], traw_ptr tunit, Simple));
  Hashtbl.add tbl "__unsafe_clsptr"
    (Unsafe_clsptr, Tfun ([ { pm with pt = Qvar "0" } ], traw_ptr tunit, Simple));
  Hashtbl.add tbl "__unsafe_leak"
    ( Unsafe_leak,
      Tfun ([ { pm with pt = Qvar "0"; pattr = Dmove } ], tunit, Simple) );
  Hashtbl.add tbl "__unsafe_unchecked"
    (Unsafe_unchecked, Tfun ([ { po with pt = Qvar "0" } ], Qvar "0", Simple));
  Hashtbl.add tbl "is_nullptr"
    (Is_nullptr, Tfun ([ { pm with pt = traw_ptr (Qvar "0") } ], tbool, Simple));
  Hashtbl.add tbl "assert"
    (Assert, Tfun ([ { pm with pt = tbool } ], tunit, Simple));
  Hashtbl.add tbl "copy"
    (Copy, Tfun ([ { pm with pt = Qvar "0" } ], Qvar "0", Simple));
  Hashtbl.add tbl "land"
    (Land, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lor"
    (Lor, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lxor"
    (Lxor, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lshl"
    (Lshl, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lshr"
    (Lshr, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "ashr"
    (Ashr, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__addi"
    (Addi, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__subi"
    (Subi, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__multi"
    ( Multi,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple) );
  Hashtbl.add tbl "__divi"
    (Divi, Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__diviu"
    ( Diviu,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tint, Simple) );
  Hashtbl.add tbl "__addf"
    ( Addf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__subf"
    ( Subf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__mulf"
    ( Mulf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__divf"
    ( Divf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__lessi"
    ( Lessi,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__greateri"
    ( Greateri,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__lesseqi"
    ( Lesseqi,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__greatereqi"
    ( Greatereqi,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__lessiu"
    ( Lessiu,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__greateriu"
    ( Greateriu,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__lesseqiu"
    ( Lesseqiu,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__greatereqiu"
    ( Greatereqiu,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__equali"
    ( Equali,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__nequali"
    ( Nequali,
      Tfun ([ { pm with pt = tint }; { pm with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__lessf"
    ( Lessf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__greaterf"
    ( Greaterf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__lesseqf"
    ( Lesseqf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__greatereqf"
    ( Greatereqf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__equalf"
    ( Equalf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__nequalf"
    ( Nequalf,
      Tfun ([ { pm with pt = tfloat }; { pm with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__rc_create"
    ( Rc_create,
      Tfun ([ { pm with pt = Qvar "0"; pattr = Dmove } ], trc (Qvar "0"), Simple)
    );
  Hashtbl.add tbl "__unsafe_rc_get"
    (Unsafe_rc_get, Tfun ([ { pm with pt = trc (Qvar "0") } ], Qvar "0", Simple));
  Hashtbl.add tbl "__rc_to_weak"
    ( Rc_to_weak,
      Tfun ([ { pm with pt = trc (Qvar "0") } ], tweak_rc (Qvar "0"), Simple) );
  Hashtbl.add tbl "__unsafe_rc_of_weak"
    ( Unsafe_rc_of_weak,
      Tfun ([ { pm with pt = tweak_rc (Qvar "0") } ], trc (Qvar "0"), Simple) );
  Hashtbl.add tbl "__rc_cnt"
    (Rc_cnt, Tfun ([ { pm with pt = trc (Qvar "0") } ], tint, Simple));
  Hashtbl.add tbl "__rc_cntw"
    (Rc_wcnt, Tfun ([ { pm with pt = tweak_rc (Qvar "0") } ], tint, Simple));
  Hashtbl.add tbl "__any_abort" (Any_abort, Tfun ([], Qvar "0", Simple));
  Hashtbl.add tbl "__any_exit"
    (Any_exit, Tfun ([ { pm with pt = ti32 } ], Qvar "0", Simple));

  let castable_types =
    [ tint; tfloat; ti32; tu32; tf32; tbool; ti8; tu8; ti16; tu16 ]
  in
  List.iteri
    (fun i to_ ->
      List.iteri
        (fun j of_ ->
          if i <> j then
            let name =
              Printf.sprintf "%s_of_%s"
                (string_of_type Path.(Pid "") to_)
                (string_of_type Path.(Pid "") of_)
            in
            Hashtbl.add tbl name
              (Cast (to_, of_), Tfun ([ { pm with pt = of_ } ], to_, Simple)))
        castable_types)
    castable_types;

  tbl

let of_string key =
  let key =
    match key with
    | "__copy" ->
        (* To make sure copy is not shadowed for string literals.
           See exclusivity *)
        "copy"
    | _ -> key
  in
  Hashtbl.find_opt tbl key |> Option.map fst

let fold f init = Hashtbl.fold f tbl init
