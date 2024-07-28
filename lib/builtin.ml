type t =
  | Unsafe_ptr_get
  | Unsafe_ptr_set
  | Unsafe_ptr_at
  | Unsafe_ptr_reinterpret
  | Unsafe_addr
  | Realloc
  | Malloc
  | Ignore
  | Int_of_float
  | Int_of_f32
  | Int_of_i32
  | Float_of_int
  | Float_of_f32
  | Float_of_i32
  | I32_of_int
  | I32_of_float
  | I32_of_f32
  | U8_of_int
  | U8_to_int
  | U16_of_int
  | U16_to_int
  | F32_of_float
  | F32_of_int
  | F32_of_i32
  | Not
  | Mod
  | Array_get
  | Array_length
  | Array_drop_back
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
  | Addf
  | Subf
  | Mulf
  | Divf
  | Lessi
  | Greateri
  | Lesseqi
  | Greatereqi
  | Equali
  | Lessf
  | Greaterf
  | Lesseqf
  | Greatereqf
  | Equalf
  | Rc_create
  | Rc_get
[@@deriving show]

let tbl =
  let open Types in
  let p = { Types.pattr = Dnorm; pt = tunit } in
  let tbl = Hashtbl.create 64 in

  Hashtbl.add tbl "__unsafe_ptr_get"
    ( Unsafe_ptr_get,
      Types.Tfun
        ( [ { p with pt = traw_ptr (Qvar "0") }; { p with pt = tint } ],
          Qvar "0",
          Simple ) );
  Hashtbl.add tbl "__unsafe_ptr_set"
    ( Unsafe_ptr_set,
      Tfun
        ( [
            { pt = traw_ptr (Qvar "0"); pattr = Dmut };
            { p with pt = tint };
            { pt = Qvar "0"; pattr = Dmove };
          ],
          tunit,
          Simple ) );
  Hashtbl.add tbl "__unsafe_ptr_at"
    ( Unsafe_ptr_at,
      Tfun
        ( [ { p with pt = traw_ptr (Qvar "0") }; { p with pt = tint } ],
          traw_ptr (Qvar "0"),
          Simple ) );
  Hashtbl.add tbl "__unsafe_ptr_reinterpret"
    ( Unsafe_ptr_reinterpret,
      Tfun ([ { p with pt = traw_ptr (Qvar "0") } ], traw_ptr (Qvar "1"), Simple)
    );
  Hashtbl.add tbl "__unsafe_addr"
    ( Unsafe_addr,
      Tfun ([ { pt = Qvar "0"; pattr = Dmut } ], traw_ptr (Qvar "0"), Simple) );
  Hashtbl.add tbl "__realloc"
    ( Realloc,
      Tfun
        ( [ { pt = traw_ptr (Qvar "0"); pattr = Dmut }; { p with pt = tint } ],
          tunit,
          Simple ) );
  Hashtbl.add tbl "__malloc"
    (Malloc, Tfun ([ { p with pt = tint } ], traw_ptr (Qvar "0"), Simple));
  Hashtbl.add tbl "ignore"
    (Ignore, Tfun ([ { p with pt = Qvar "0" } ], tunit, Simple));
  Hashtbl.add tbl "int_of_float"
    (Int_of_float, Tfun ([ { p with pt = tfloat } ], tint, Simple));
  Hashtbl.add tbl "int_of_i32"
    (Int_of_i32, Tfun ([ { p with pt = ti32 } ], tint, Simple));
  Hashtbl.add tbl "int_of_f32"
    (Int_of_f32, Tfun ([ { p with pt = tf32 } ], tint, Simple));
  Hashtbl.add tbl "float_of_int"
    (Float_of_int, Tfun ([ { p with pt = tint } ], tfloat, Simple));
  Hashtbl.add tbl "float_of_f32"
    (Float_of_f32, Tfun ([ { p with pt = tf32 } ], tfloat, Simple));
  Hashtbl.add tbl "float_of_i32"
    (Float_of_i32, Tfun ([ { p with pt = ti32 } ], tfloat, Simple));
  Hashtbl.add tbl "i32_of_int"
    (I32_of_int, Tfun ([ { p with pt = tint } ], ti32, Simple));
  Hashtbl.add tbl "i32_of_float"
    (I32_of_float, Tfun ([ { p with pt = tfloat } ], ti32, Simple));
  Hashtbl.add tbl "i32_of_f32"
    (I32_of_f32, Tfun ([ { p with pt = tf32 } ], ti32, Simple));
  Hashtbl.add tbl "f32_of_float"
    (F32_of_float, Tfun ([ { p with pt = tfloat } ], tf32, Simple));
  Hashtbl.add tbl "f32_of_int"
    (F32_of_int, Tfun ([ { p with pt = tint } ], tf32, Simple));
  Hashtbl.add tbl "f32_of_i32"
    (F32_of_i32, Tfun ([ { p with pt = ti32 } ], tf32, Simple));
  Hashtbl.add tbl "u8_of_int"
    (U8_of_int, Tfun ([ { p with pt = tint } ], tu8, Simple));
  Hashtbl.add tbl "u8_to_int"
    (U8_to_int, Tfun ([ { p with pt = tu8 } ], tint, Simple));
  Hashtbl.add tbl "u16_of_int"
    (U16_of_int, Tfun ([ { p with pt = tint } ], tu16, Simple));
  Hashtbl.add tbl "u16_to_int"
    (U16_to_int, Tfun ([ { p with pt = tu16 } ], tint, Simple));
  Hashtbl.add tbl "not" (Not, Tfun ([ { p with pt = tbool } ], tbool, Simple));
  Hashtbl.add tbl "mod"
    (Mod, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__array_get"
    ( Array_get,
      Tfun
        ( [ { p with pt = tarray (Qvar "0") }; { p with pt = tint } ],
          Qvar "0",
          Simple ) );
  Hashtbl.add tbl "__array_length"
    (Array_length, Tfun ([ { p with pt = tarray (Qvar "0") } ], tint, Simple));
  Hashtbl.add tbl "__array_drop_back"
    ( Array_drop_back,
      Tfun ([ { pt = tarray (Qvar "0"); pattr = Dmut } ], tunit, Simple) );
  Hashtbl.add tbl "__array_data"
    ( Array_data,
      Tfun ([ { p with pt = tarray (Qvar "0") } ], traw_ptr (Qvar "0"), Simple)
    );
  Hashtbl.add tbl "__array_capacity"
    (Array_capacity, Tfun ([ { p with pt = tarray (Qvar "0") } ], tint, Simple));
  Hashtbl.add tbl "__fixed_array_get"
    ( Fixed_array_get,
      Tfun
        ( [
            { p with pt = Tfixed_array (ref (Types.Generalized "0"), Qvar "0") };
            { p with pt = tint };
          ],
          Qvar "0",
          Simple ) );
  Hashtbl.add tbl "__fixed_array_length"
    ( Fixed_array_length,
      Tfun
        ( [
            { p with pt = Tfixed_array (ref (Types.Generalized "0"), Qvar "0") };
          ],
          tint,
          Simple ) );
  Hashtbl.add tbl "__fixed_array_data"
    ( Fixed_array_data,
      Tfun
        ( [
            { p with pt = Tfixed_array (ref (Types.Generalized "0"), Qvar "0") };
          ],
          traw_ptr (Qvar "0"),
          Simple ) );
  Hashtbl.add tbl "__unsafe_array_realloc"
    ( Unsafe_array_realloc,
      Tfun
        ( [ { pt = tarray (Qvar "0"); pattr = Dmut }; { p with pt = tint } ],
          tunit,
          Simple ) );
  Hashtbl.add tbl "__unsafe_array_create"
    ( Unsafe_array_create,
      Tfun ([ { p with pt = tint } ], tarray (Qvar "0"), Simple) );
  Hashtbl.add tbl "__unsafe_array_length"
    ( Unsafe_array_length,
      Tfun ([ { p with pt = tarray (Qvar "0") } ], tint, Simple) );
  Hashtbl.add tbl "__unsafe_nullptr"
    (Unsafe_nullptr, Tfun ([], traw_ptr tu8, Simple));
  Hashtbl.add tbl "__unsafe_funptr"
    (Unsafe_funptr, Tfun ([ { p with pt = Qvar "0" } ], traw_ptr tunit, Simple));
  Hashtbl.add tbl "__unsafe_clsptr"
    (Unsafe_clsptr, Tfun ([ { p with pt = Qvar "0" } ], traw_ptr tunit, Simple));
  Hashtbl.add tbl "nullptr?"
    (Is_nullptr, Tfun ([ { p with pt = traw_ptr (Qvar "0") } ], tbool, Simple));
  Hashtbl.add tbl "assert"
    (Assert, Tfun ([ { p with pt = tbool } ], tunit, Simple));
  Hashtbl.add tbl "copy"
    (Copy, Tfun ([ { p with pt = Qvar "0" } ], Qvar "0", Simple));
  Hashtbl.add tbl "land"
    (Land, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lor"
    (Lor, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lxor"
    (Lxor, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lshl"
    (Lshl, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "lshr"
    (Lshr, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "ashr"
    (Ashr, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__addi"
    (Addi, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__subi"
    (Subi, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__multi"
    (Multi, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__divi"
    (Divi, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tint, Simple));
  Hashtbl.add tbl "__addf"
    ( Addf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__subf"
    ( Subf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__mulf"
    ( Mulf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__divf"
    ( Divf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tfloat, Simple)
    );
  Hashtbl.add tbl "__lessi"
    (Lessi, Tfun ([ { p with pt = tint }; { p with pt = tint } ], tbool, Simple));
  Hashtbl.add tbl "__greateri"
    ( Greateri,
      Tfun ([ { p with pt = tint }; { p with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__lesseqi"
    ( Lesseqi,
      Tfun ([ { p with pt = tint }; { p with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__greatereqi"
    ( Greatereqi,
      Tfun ([ { p with pt = tint }; { p with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__equali"
    ( Equali,
      Tfun ([ { p with pt = tint }; { p with pt = tint } ], tbool, Simple) );
  Hashtbl.add tbl "__lessf"
    ( Lessf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__greaterf"
    ( Greaterf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__lesseqf"
    ( Lesseqf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__greatereqf"
    ( Greatereqf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__equalf"
    ( Equalf,
      Tfun ([ { p with pt = tfloat }; { p with pt = tfloat } ], tbool, Simple)
    );
  Hashtbl.add tbl "__rc_create"
    ( Rc_create,
      Tfun ([ { pt = Qvar "0"; pattr = Dmove } ], trc (Qvar "0"), Simple) );
  Hashtbl.add tbl "__rc_get"
    (Rc_get, Tfun ([ { p with pt = trc (Qvar "0") } ], Qvar "0", Simple));

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
