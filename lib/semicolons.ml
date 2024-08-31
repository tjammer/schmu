exception Error of string

type context = Block | Parens

type state = {
  last : Parser.token;
  context : context list;
  lnum : int;
  buffered : Parser.token option;
}

let default_state =
  { last = Parser.Lcurly; context = [ Block ]; lnum = 0; buffered = None }

let saved_state = ref default_state
let reset () = saved_state := default_state

let default next state =
  (* TODO check closing and opening of context *)
  saved_state := { state with last = next };
  next

let rec newline ~lnum lexbuf next state =
  print_endline "newline";
  match state.context with
  | Parens :: _ ->
      (* Ignore newlines in parens *)
      print_endline "default parens";
      default next { state with lnum }
  | Block :: _ -> (
      match (state.last, next) with
      | _, (Parser.Dot | Eof | Rcurly | Else) ->
          print_endline "default dot";
          (* Ignore newline. Rcurly closes the block, thus we ignore it on
             newlines, expect in record expressions. *)
          default next { state with lnum }
      | Parser.Semicolon, Semicolon ->
          print_endline "ignore semicolon";
          (* Ignore following semicolons *)
          saved_state := { state with lnum };
          read lexbuf
      | ( ( Parser.Rpar | Ident _ | Builtin_id _ | Rbrack | Rcurly | Int _
          | U8 _ | U16 _ | I32 _ | F32 _ | True | False ),
          _ ) ->
          print_endline "semicolon";
          (* These could end a statement, insert Semicolon *)
          saved_state :=
            { state with lnum; buffered = Some next; last = Semicolon };
          Semicolon
      | _ ->
          print_endline "default newline";
          default next { state with lnum })
  | [] -> failwith "unreachable"

and read lexbuf =
  match !saved_state.buffered with
  | Some token ->
      print_endline "buffered";
      saved_state := { !saved_state with buffered = None };
      token
  | None ->
      let token = Lexer.read lexbuf in
      let pos = Lexing.(lexbuf.lex_start_p) in
      if not (Int.equal pos.pos_lnum !saved_state.lnum) then
        newline ~lnum:pos.pos_lnum lexbuf token !saved_state
      else (
        print_endline "default newline";
        default token !saved_state)
