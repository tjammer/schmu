type t =
  | Unsafe_ptr_get
  | Unsafe_ptr_set
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
  | Array_get
  | Array_set
[@@deriving show]

let tbl =
  let pmut = false in
  [
    ( Unsafe_ptr_get,
      Types.Tfun
        ( [ { pt = Traw_ptr (Qvar "0"); pmut }; { pt = Tint; pmut } ],
          Qvar "0",
          Simple ),
      "__unsafe_ptr_get" );
    ( Unsafe_ptr_set,
      Tfun
        ( [
            { pt = Traw_ptr (Qvar "0"); pmut };
            { pt = Tint; pmut };
            { pt = Qvar "0"; pmut };
          ],
          Tunit,
          Simple ),
      "__unsafe_ptr_set" );
    ( Realloc,
      Tfun
        ( [ { pmut = true; pt = Traw_ptr (Qvar "0") }; { pmut; pt = Tint } ],
          Tunit,
          Simple ),
      "__realloc" );
    ( Malloc,
      Tfun ([ { pmut; pt = Tint } ], Traw_ptr (Qvar "0"), Simple),
      "__malloc" );
    (Ignore, Tfun ([ { pmut; pt = Qvar "0" } ], Tunit, Simple), "ignore");
    ( Int_of_float,
      Tfun ([ { pmut; pt = Tfloat } ], Tint, Simple),
      "int_of_float" );
    (Int_of_i32, Tfun ([ { pmut; pt = Ti32 } ], Tint, Simple), "int_of_i32");
    (Int_of_f32, Tfun ([ { pmut; pt = Tf32 } ], Tint, Simple), "int_of_f32");
    ( Float_of_int,
      Tfun ([ { pmut; pt = Tint } ], Tfloat, Simple),
      "float_of_int" );
    ( Float_of_f32,
      Tfun ([ { pmut; pt = Tf32 } ], Tfloat, Simple),
      "float_of_f32" );
    ( Float_of_i32,
      Tfun ([ { pmut; pt = Ti32 } ], Tfloat, Simple),
      "float_of_i32" );
    (I32_of_int, Tfun ([ { pmut; pt = Tint } ], Ti32, Simple), "i32_of_int");
    ( I32_of_float,
      Tfun ([ { pmut; pt = Tfloat } ], Ti32, Simple),
      "i32_of_float" );
    (I32_of_f32, Tfun ([ { pmut; pt = Tf32 } ], Ti32, Simple), "i32_of_f32");
    ( F32_of_float,
      Tfun ([ { pmut; pt = Tfloat } ], Tf32, Simple),
      "f32_of_float" );
    (F32_of_int, Tfun ([ { pmut; pt = Tint } ], Tf32, Simple), "f32_of_int");
    (F32_of_i32, Tfun ([ { pmut; pt = Ti32 } ], Tf32, Simple), "f32_of_i32");
    (U8_of_int, Tfun ([ { pmut; pt = Tint } ], Tu8, Simple), "u8_of_int");
    (U8_to_int, Tfun ([ { pmut; pt = Tu8 } ], Tint, Simple), "u8_to_int");
    (Not, Tfun ([ { pmut; pt = Tbool } ], Tbool, Simple), "not");
    ( Array_get,
      Tfun
        ( [ { pmut; pt = Tarray (Qvar "0") }; { pmut; pt = Tint } ],
          Qvar "0",
          Simple ),
      "array-get" );
    ( Array_set,
      Tfun
        ( [
            { pmut = true; pt = Tarray (Qvar "0") };
            { pmut; pt = Tint };
            { pmut; pt = Qvar "0" };
          ],
          Tunit,
          Simple ),
      "array-set" );
  ]

let of_string = function
  | "__unsafe_ptr_get" -> Some Unsafe_ptr_get
  | "__unsafe_ptr_set" -> Some Unsafe_ptr_set
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
  | "array-get" -> Some Array_get
  | "array-set" -> Some Array_set
  | _ -> None

let fold f init = List.fold_left f init tbl
