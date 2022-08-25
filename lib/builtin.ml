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
[@@deriving show]

let tbl =
  [
    ( Unsafe_ptr_get,
      Types.Tfun ([ Traw_ptr (Qvar "0"); Tint ], Qvar "0", Simple),
      "__unsafe_ptr_get" );
    ( Unsafe_ptr_set,
      Tfun ([ Traw_ptr (Qvar "0"); Tint; Qvar "0" ], Tunit, Simple),
      "__unsafe_ptr_set" );
    ( Realloc,
      Tfun ([ Traw_ptr (Qvar "0"); Tint ], Traw_ptr (Qvar "0"), Simple),
      "__realloc" );
    (Malloc, Tfun ([ Tint ], Traw_ptr (Qvar "0"), Simple), "__malloc");
    (Ignore, Tfun ([ Qvar "0" ], Tunit, Simple), "ignore");
    (Int_of_float, Tfun ([ Tfloat ], Tint, Simple), "int_of_float");
    (Int_of_i32, Tfun ([ Ti32 ], Tint, Simple), "int_of_i32");
    (Int_of_f32, Tfun ([ Tf32 ], Tint, Simple), "int_of_f32");
    (Float_of_int, Tfun ([ Tint ], Tfloat, Simple), "float_of_int");
    (Float_of_f32, Tfun ([ Tf32 ], Tfloat, Simple), "float_of_f32");
    (Float_of_i32, Tfun ([ Ti32 ], Tfloat, Simple), "float_of_i32");
    (I32_of_int, Tfun ([ Tint ], Ti32, Simple), "i32_of_int");
    (I32_of_float, Tfun ([ Tfloat ], Ti32, Simple), "i32_of_float");
    (I32_of_f32, Tfun ([ Tf32 ], Ti32, Simple), "i32_of_f32");
    (F32_of_float, Tfun ([ Tfloat ], Tf32, Simple), "f32_of_float");
    (F32_of_int, Tfun ([ Tint ], Tf32, Simple), "f32_of_int");
    (F32_of_i32, Tfun ([ Ti32 ], Tf32, Simple), "f32_of_i32");
    (U8_of_int, Tfun ([ Tint ], Tu8, Simple), "u8_of_int");
    (U8_to_int, Tfun ([ Tu8 ], Tint, Simple), "u8_to_int");
    (Not, Tfun ([ Tbool ], Tbool, Simple), "not");
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
  | _ -> None

let fold f init = List.fold_left f init tbl
