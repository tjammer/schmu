type t = Unsafe_ptr_get | Unsafe_ptr_set | Realloc | Ignore [@@deriving show]

let of_string = function
  | "__unsafe_ptr_get" -> Some Unsafe_ptr_get
  | "__unsafe_ptr_set" -> Some Unsafe_ptr_set
  | "__realloc" -> Some Realloc
  | "ignore" -> Some Ignore
  | _ -> None

let to_string = function
  | Unsafe_ptr_get -> "__unsafe_ptr_get"
  | Unsafe_ptr_set -> "__unsafe_ptr_set"
  | Realloc -> "__realloc"
  | Ignore -> "ignore"

let to_type = function
  | Unsafe_ptr_get -> Types.Tfun ([ Tptr (Qvar "0"); Tint ], Qvar "0", Simple)
  | Unsafe_ptr_set -> Tfun ([ Tptr (Qvar "0"); Tint; Qvar "0" ], Tunit, Simple)
  | Realloc -> Tfun ([ Tptr (Qvar "0"); Tint ], Tptr (Qvar "0"), Simple)
  | Ignore -> Tfun ([ Qvar "0" ], Tunit, Simple)

let fold f init =
  List.fold_left f init [ Unsafe_ptr_get; Unsafe_ptr_set; Realloc; Ignore ]
