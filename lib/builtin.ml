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
[@@deriving show]

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
  | _ -> None

let to_string = function
  | Unsafe_ptr_get -> "__unsafe_ptr_get"
  | Unsafe_ptr_set -> "__unsafe_ptr_set"
  | Realloc -> "__realloc"
  | Malloc -> "__malloc"
  | Ignore -> "ignore"
  | Int_of_float -> "int_of_float"
  | Float_of_int -> "float_of_int"
  | I32_of_int -> "i32_of_int"
  | I32_to_int -> "i32_to_int"
  | U8_of_int -> "u8_of_int"
  | U8_to_int -> "u8_to_int"

let to_type = function
  | Unsafe_ptr_get -> Types.Tfun ([ Tptr (Qvar "0"); Tint ], Qvar "0", Simple)
  | Unsafe_ptr_set -> Tfun ([ Tptr (Qvar "0"); Tint; Qvar "0" ], Tunit, Simple)
  | Realloc -> Tfun ([ Tptr (Qvar "0"); Tint ], Tptr (Qvar "0"), Simple)
  | Malloc -> Tfun ([ Tint ], Tptr (Qvar "0"), Simple)
  | Ignore -> Tfun ([ Qvar "0" ], Tunit, Simple)
  | Int_of_float -> Tfun ([ Tfloat ], Tint, Simple)
  | Float_of_int -> Tfun ([ Tint ], Tfloat, Simple)
  | I32_of_int -> Tfun ([ Tint ], Ti32, Simple)
  | I32_to_int -> Tfun ([ Ti32 ], Tint, Simple)
  | U8_of_int -> Tfun ([ Tint ], Tu8, Simple)
  | U8_to_int -> Tfun ([ Tu8 ], Tint, Simple)

let fold f init =
  List.fold_left f init
    [
      Unsafe_ptr_get;
      Unsafe_ptr_set;
      Realloc;
      Malloc;
      Ignore;
      Int_of_float;
      Float_of_int;
      I32_of_int;
      I32_to_int;
      U8_of_int;
      U8_to_int;
    ]
