{
open Parser
open Lexing

exception SyntaxError of string

let next_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <-
    { pos with pos_bol = pos.pos_cnum;
               pos_lnum = pos.pos_lnum + 1
    }

let u8_of_string str =
  (* TODO handle exceptions *)
  String.sub str 0 (String.length str - 2)
    |> int_of_string
    |> Char.chr

let u16_of_string str =
  String.sub str 0 (String.length str - 2)
    |> int_of_string

let f_of_string f str =
  String.sub str 0 (String.length str - 3)
  |> f

let name_of_string str =
  String.sub str 1 (String.length str - 1)

let mut_name_of_string str =
  String.sub str 1 (String.length str - 2)

let mut_of_string str =
  String.sub str 0 (String.length str - 1)

let hex_digit_value d =
  let d = Char.code d in
  if d >= 97 then d - 87 else
  if d >= 65 then d - 55 else
  d - 48

let decimal_code c d u =
  100 * (Char.code c - 48) + 10 * (Char.code d - 48) + (Char.code u - 48)

let hexadecimal_code s =
  let rec loop acc i =
    if i < String.length s then
      let value = hex_digit_value s.[i] in
      loop (16 * acc + value) (i + 1)
    else acc in
  loop 0 0

let char_for_octal_code c d u =
  let c = 64 * (Char.code c - 48) +
           8 * (Char.code d - 48) +
               (Char.code u - 48) in
  Char.chr c

let char_for_hexadecimal_code d u =
  Char.chr (16 * (hex_digit_value d) + (hex_digit_value u))

let char_for_backslash = function
    'n' -> '\010'
  | 'r' -> '\013'
  | 'b' -> '\008'
  | 't' -> '\009'
  | c   -> c

let int_of_intlit lit =
  String.split_on_char '\'' lit |> String.concat "" |> Int64.of_string |> Int64.to_int

let int_of_hashnum s = String.sub s 1 (String.length s - 2) |> int_of_intlit

}

let digit = ['0'-'9']
let lowercase_alpha = ['a'-'z']
let uppercase_alpha = ['A'-'Z']
let min = '-'
let hex_literal =
  '0' ['x' 'X'] ['0'-'9' 'A'-'F' 'a'-'f']['0'-'9' 'A'-'F' 'a'-'f' '_']*
let oct_literal =
  '0' ['o' 'O'] ['0'-'7'] ['0'-'7' '_']*
let bin_literal =
  '0' ['b' 'B'] ['0'-'1'] ['0'-'1' '_']*
let digits = digit (digit | ('_' | digit))*
let int_lit = (digits | hex_literal | oct_literal | bin_literal)

let int = int_lit
let u8 = digit+ "u8"
let u16 = digit+ "u16"
let float = digit+ '.' digit+
let i32 = min? int_lit "i32"
let f32 = min? float "f32"

let tail = (lowercase_alpha|uppercase_alpha|digit|'_')*
let lowercase_id = lowercase_alpha tail
let ident = '_'? (lowercase_alpha) tail
let builtin_id = "__" lowercase_id
let path_id = lowercase_id '/'
let ctor_id = uppercase_alpha tail?

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"
let backslash_escapes = ['\\' '\'' '"' 'n' 't' 'b' 'r' ' ']

let plus_ops = '+' | '-'
let mult_ops = '*' | '/'
let cmp_ops = '<' | '>'
let binops = '=' | cmp_ops | plus_ops | mult_ops | '.' | '|' | '&' | '?'
let eq_op = '=' binops+
let cmp_op = cmp_ops binops*
let plus_op = plus_ops binops*
let mult_op = mult_ops binops*

rule read =
  parse
  | white    { read lexbuf }
  | newline  { next_line lexbuf; read lexbuf }
  | int      { Int (int_of_intlit (Lexing.lexeme lexbuf)) }
  | float    { Float (float_of_string (Lexing.lexeme lexbuf)) }
  | u8       { U8 (u8_of_string (Lexing.lexeme lexbuf)) }
  | u16      { U16 (u16_of_string (Lexing.lexeme lexbuf)) }
  | i32      { I32 (f_of_string int_of_intlit (Lexing.lexeme lexbuf)) }
  | f32      { F32 (f_of_string float_of_string (Lexing.lexeme lexbuf)) }
  | "true"   { True }
  | "false"  { False }
  | "and"    { And }
  | "or"     { Or }
  | "import" { Import }
  | '='      { Equal }
  | ':'      { Colon }
  | ','      { Comma }
  | '.'      { Dot }
  | "'"      { Quote }
  | "if"     { If }
  | "else"   { Else }
  | "fun"    { Fun }
  | "let"    { Let }
  | "match"  { Match }
  | "use" { Use }
  | "type"   { Type }
  | "external"{ External }
  | "signature" { Signature }
  | "module" { Module }
  | "functor" { Functor }
  | "fmt"    { Fmt }
  | "with"   { With }
  | "val"    { Val }
  | "rec"    { Rec }
  | '|'      { Hbar }
  | ';'      { Semicolon }
  | ident    { Ident (Lexing.lexeme lexbuf) }
  | builtin_id { Builtin_id (Lexing.lexeme lexbuf) }
  | path_id  { Path_id (Lexing.lexeme lexbuf |> mut_of_string) }
  | ctor_id  { Ctor (Lexing.lexeme lexbuf |> String.lowercase_ascii) }
  | '_'      { Wildcard }
  | '"'      { read_string (Buffer.create 17) lexbuf }
  | "'" [^ '\\'] "'" { U8 (Lexing.lexeme_char lexbuf 1) }
  | "'" '\\' backslash_escapes "'" { U8 (char_for_backslash (Lexing.lexeme_char lexbuf 2)) }
  | "'" '\\' (['0'-'9'] as c) (['0'-'9'] as d) (['0'-'9'] as u)"'"
    { let v = decimal_code c d u in
      if v > 255 then
        raise (SyntaxError
          (Printf.sprintf "Illegal escape sequence \\%c%c%c" c d u))
      else
        U8 (Char.chr v) }
  | "'" '\\' 'x'
       (['0'-'9' 'a'-'f' 'A'-'F'] as d) (['0'-'9' 'a'-'f' 'A'-'F'] as u) "'"
       { U8 (char_for_hexadecimal_code d u) }
  | '&'      { Ampersand }
  | '!'      { Exclamation }
  | '('      { Lpar }
  | ')'      { Rpar }
  | '{'      { Lcurly }
  | '}'      { Rcurly }
  | '['      { Lbrack }
  | ']'      { Rbrack }
  | "#?"     { Hash_quest }
  | '#'      { Hash }
  | "->"     { Right_arrow }
  | "--"      { line_comment lexbuf }
  | eq_op    { Eq_op (Lexing.lexeme lexbuf) }
  | cmp_op   { Cmp_op (Lexing.lexeme lexbuf) }
  | plus_op  { Plus_op (Lexing.lexeme lexbuf) }
  | mult_op  { Mult_op (Lexing.lexeme lexbuf) }
  | eof      { Eof }
  | _ { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }

and line_comment =
  parse
  | newline { next_line lexbuf; read lexbuf }
  | eof     { Eof }
  | _       { line_comment lexbuf }

and read_string buf =
  parse
  | newline { next_line lexbuf; read_string buf lexbuf }
  | '"'       { String_lit (Buffer.contents buf) }
  | '\\' '/'  { Buffer.add_char buf '/'; read_string buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf }
  | '\\' 'b'  { Buffer.add_char buf '\b'; read_string buf lexbuf }
  | '\\' 'f'  { Buffer.add_char buf '\012'; read_string buf lexbuf }
  | '\\' 'n'  { Buffer.add_char buf '\n'; read_string buf lexbuf }
  | '\\' 'r'  { Buffer.add_char buf '\r'; read_string buf lexbuf }
  | '\\' 't'  { Buffer.add_char buf '\t'; read_string buf lexbuf }
  | '\\' '"'  { Buffer.add_char buf '"'; read_string buf lexbuf }
  | '\\' (['0'-'9'] as c) (['0'-'9'] as d) (['0'-'9']  as u)
    { let v = decimal_code c d u in
        if v > 255 then
          raise (SyntaxError (Printf.sprintf
              "Illegal backslash escape in string: '\\%c%c%c'" c d u))
        else
          Buffer.add_char buf (Char.chr v);
          read_string buf lexbuf }
  | [^ '"' '\\' '\n' '\r']+
    { Buffer.add_string buf (Lexing.lexeme lexbuf);
      read_string buf lexbuf
    }
  | _ { raise (SyntaxError ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
  | eof { raise (SyntaxError ("String is not terminated")) }
