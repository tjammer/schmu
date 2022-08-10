type t =
  | Unsafe_ptr_get
  | Unsafe_ptr_set
  | Realloc
  | Malloc
  | Ignore
  | Int_of_float
  | Float_of_int
  | I32_of_int
  | I32_to_int
  | U8_of_int
  | U8_to_int
  | F32_of_float
  | F32_to_float
  | Not
[@@deriving show]

let tbl =
  [
    ( Unsafe_ptr_get,
      Types.Tfun ([ Tptr (Qvar "0"); Tint ], Qvar "0", Simple),
      "__unsafe_ptr_get" );
    ( Unsafe_ptr_set,
      Tfun ([ Tptr (Qvar "0"); Tint; Qvar "0" ], Tunit, Simple),
      "__unsafe_ptr_set" );
    ( Realloc,
      Tfun ([ Tptr (Qvar "0"); Tint ], Tptr (Qvar "0"), Simple),
      "__realloc" );
    (Malloc, Tfun ([ Tint ], Tptr (Qvar "0"), Simple), "__malloc");
    (Ignore, Tfun ([ Qvar "0" ], Tunit, Simple), "ignore");
    (Int_of_float, Tfun ([ Tfloat ], Tint, Simple), "int_of_float");
    (Float_of_int, Tfun ([ Tint ], Tfloat, Simple), "float_of_int");
    (I32_of_int, Tfun ([ Tint ], Ti32, Simple), "i32_of_int");
    (I32_to_int, Tfun ([ Ti32 ], Tint, Simple), "i32_to_int");
    (U8_of_int, Tfun ([ Tint ], Tu8, Simple), "u8_of_int");
    (U8_to_int, Tfun ([ Tu8 ], Tint, Simple), "u8_to_int");
    (F32_of_float, Tfun ([ Tfloat ], Tf32, Simple), "f32_of_float");
    (F32_to_float, Tfun ([ Tf32 ], Tfloat, Simple), "f32_to_float");
    (Not, Tfun ([ Tbool ], Tbool, Simple), "not");
  ]

let of_string = function
  | "__unsafe_ptr_get" -> Some Unsafe_ptr_get
  | "__unsafe_ptr_set" -> Some Unsafe_ptr_set
  | "__realloc" -> Some Realloc
  | "__malloc" -> Some Malloc
  | "ignore" -> Some Ignore
  | "int_of_float" -> Some Int_of_float
  | "float_of_int" -> Some Float_of_int
  | "i32_of_int" -> Some I32_of_int
  | "i32_to_int" -> Some I32_to_int
  | "u8_of_int" -> Some U8_of_int
  | "u8_to_int" -> Some U8_to_int
  | "f32_of_float" -> Some F32_of_float
  | "f32_to_float" -> Some F32_to_float
  | "not" -> Some Not
  | _ -> None

let fold f init = List.fold_left f init tbl
