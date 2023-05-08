type t =
  | Unsafe_ptr_get
  | Unsafe_ptr_set
  | Unsafe_ptr_at
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
  | F32_of_float
  | F32_of_int
  | F32_of_i32
  | Not
  | Mod
  | Array_get
  | Array_set
  | Array_length
  | Array_push
  | Array_drop_back
  | Array_data
  | Unsafe_array_create
  | Unsafe_nullptr
  | Assert
  | Copy
[@@deriving show]

let tbl =
  let p = { Types.pattr = None; pt = Tunit } in
  [
    ( Unsafe_ptr_get,
      Types.Tfun
        ( [ { p with pt = Traw_ptr (Qvar "0") }; { p with pt = Tint } ],
          Qvar "0",
          Simple ),
      "__unsafe_ptr_get" );
    ( Unsafe_ptr_set,
      Tfun
        ( [
            { pt = Traw_ptr (Qvar "0"); pattr = Some Dmut };
            { p with pt = Tint };
            { p with pt = Qvar "0" };
          ],
          Tunit,
          Simple ),
      "__unsafe_ptr_set" );
    ( Unsafe_ptr_at,
      Tfun
        ( [ { p with pt = Traw_ptr (Qvar "0") }; { p with pt = Tint } ],
          Traw_ptr (Qvar "0"),
          Simple ),
      "__unsafe_ptr_at" );
    ( Realloc,
      Tfun
        ( [
            { pt = Traw_ptr (Qvar "0"); pattr = Some Dmut }; { p with pt = Tint };
          ],
          Tunit,
          Simple ),
      "__realloc" );
    ( Malloc,
      Tfun ([ { p with pt = Tint } ], Traw_ptr (Qvar "0"), Simple),
      "__malloc" );
    (Ignore, Tfun ([ { p with pt = Qvar "0" } ], Tunit, Simple), "ignore");
    ( Int_of_float,
      Tfun ([ { p with pt = Tfloat } ], Tint, Simple),
      "int_of_float" );
    (Int_of_i32, Tfun ([ { p with pt = Ti32 } ], Tint, Simple), "int_of_i32");
    (Int_of_f32, Tfun ([ { p with pt = Tf32 } ], Tint, Simple), "int_of_f32");
    ( Float_of_int,
      Tfun ([ { p with pt = Tint } ], Tfloat, Simple),
      "float_of_int" );
    ( Float_of_f32,
      Tfun ([ { p with pt = Tf32 } ], Tfloat, Simple),
      "float_of_f32" );
    ( Float_of_i32,
      Tfun ([ { p with pt = Ti32 } ], Tfloat, Simple),
      "float_of_i32" );
    (I32_of_int, Tfun ([ { p with pt = Tint } ], Ti32, Simple), "i32_of_int");
    ( I32_of_float,
      Tfun ([ { p with pt = Tfloat } ], Ti32, Simple),
      "i32_of_float" );
    (I32_of_f32, Tfun ([ { p with pt = Tf32 } ], Ti32, Simple), "i32_of_f32");
    ( F32_of_float,
      Tfun ([ { p with pt = Tfloat } ], Tf32, Simple),
      "f32_of_float" );
    (F32_of_int, Tfun ([ { p with pt = Tint } ], Tf32, Simple), "f32_of_int");
    (F32_of_i32, Tfun ([ { p with pt = Ti32 } ], Tf32, Simple), "f32_of_i32");
    (U8_of_int, Tfun ([ { p with pt = Tint } ], Tu8, Simple), "u8_of_int");
    (U8_to_int, Tfun ([ { p with pt = Tu8 } ], Tint, Simple), "u8_to_int");
    (Not, Tfun ([ { p with pt = Tbool } ], Tbool, Simple), "not");
    ( Mod,
      Tfun ([ { p with pt = Tint }; { p with pt = Tint } ], Tint, Simple),
      "mod" );
    ( Array_get,
      Tfun
        ( [ { p with pt = Tarray (Qvar "0") }; { p with pt = Tint } ],
          Qvar "0",
          Simple ),
      "array-get" );
    ( Array_set,
      Tfun
        ( [
            { pt = Tarray (Qvar "0"); pattr = Some Dmut };
            { p with pt = Tint };
            { p with pt = Qvar "0" };
          ],
          Tunit,
          Simple ),
      "array-set" );
    ( Array_length,
      Tfun ([ { p with pt = Tarray (Qvar "0") } ], Tint, Simple),
      "array-length" );
    ( Array_push,
      Tfun
        ( [
            { pt = Tarray (Qvar "0"); pattr = Some Dmut };
            { p with pt = Qvar "0" };
          ],
          Tunit,
          Simple ),
      "array-push" );
    ( Array_drop_back,
      Tfun ([ { pt = Tarray (Qvar "0"); pattr = Some Dmut } ], Tunit, Simple),
      "array-drop-back" );
    ( Array_data,
      Tfun ([ { p with pt = Tarray (Qvar "0") } ], Traw_ptr (Qvar "0"), Simple),
      "array-data" );
    ( Unsafe_array_create,
      Tfun ([ { p with pt = Tint } ], Tarray (Qvar "0"), Simple),
      "__unsafe_array_create" );
    (Unsafe_nullptr, Tfun ([], Traw_ptr Tu8, Simple), "__unsafe_nullptr");
    (Assert, Tfun ([ { p with pt = Tbool } ], Tunit, Simple), "assert");
    (Copy, Tfun ([ { p with pt = Qvar "0" } ], Qvar "0", Simple), "copy");
  ]

let of_string = function
  | "__unsafe_ptr_get" -> Some Unsafe_ptr_get
  | "__unsafe_ptr_set" -> Some Unsafe_ptr_set
  | "__unsafe_ptr_at" -> Some Unsafe_ptr_at
  | "__realloc" -> Some Realloc
  | "__malloc" -> Some Malloc
  | "ignore" -> Some Ignore
  | "int_of_float" -> Some Int_of_float
  | "int_of_i32" -> Some Int_of_i32
  | "int_of_f32" -> Some Int_of_f32
  | "float_of_int" -> Some Float_of_int
  | "float_of_i32" -> Some Float_of_i32
  | "float_of_f32" -> Some Float_of_f32
  | "i32_of_int" -> Some I32_of_int
  | "i32_of_f32" -> Some I32_of_f32
  | "i32_of_float" -> Some I32_of_float
  | "f32_of_int" -> Some F32_of_int
  | "f32_of_i32" -> Some F32_of_i32
  | "f32_of_float" -> Some F32_of_float
  | "u8_of_int" -> Some U8_of_int
  | "u8_to_int" -> Some U8_to_int
  | "not" -> Some Not
  | "mod" -> Some Mod
  | "array-get" -> Some Array_get
  | "array-set" -> Some Array_set
  | "array-length" -> Some Array_length
  | "array-push" -> Some Array_push
  | "array-drop-back" -> Some Array_drop_back
  | "array-data" -> Some Array_data
  | "__unsafe_array_create" -> Some Unsafe_array_create
  | "__unsafe_nullptr" -> Some Unsafe_nullptr
  | "assert" -> Some Assert
  | "copy" -> Some Copy
  | _ -> None

let fold f init = List.fold_left f init tbl
