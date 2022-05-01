open Lexing

let pp_position lexbuf file =
  let pp = Pp_loc.(pp ~max_lines:5 ~input:(Input.file file)) in
  let pos = lexbuf.lex_curr_p in
  let pos =
    Printf.sprintf "%d:%d" pos.pos_lnum (pos.pos_cnum - pos.pos_bol + 1)
  in
  (pp, pos)

let parse file lexbuf =
  let loc_of_lexing lexbuf =
    Pp_loc.Position.(of_lexing lexbuf.lex_start_p, of_lexing lexbuf.lex_curr_p)
  in
  Schmulang.(
    try Ok (Parser.prog Lexer.read lexbuf) with
    | Lexer.SyntaxError msg ->
        let loc = loc_of_lexing lexbuf in
        let pp, pos = pp_position lexbuf file in
        Error (Format.asprintf "%s:%s %s\n%!%a" file pos msg pp [ loc ])
    | Parser.Error ->
        let loc = loc_of_lexing lexbuf in
        let pp, pos = pp_position lexbuf file in
        Error
          (Format.asprintf "%s:%s %s\n%!%a" file pos "syntax error" pp [ loc ]))
