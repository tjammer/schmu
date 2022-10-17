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

let f_of_string f str =
  String.sub str 0 (String.length str - 3)
  |> f

let name_of_string str =
  String.sub str 1 (String.length str - 1)

let mut_name_of_string str =
  String.sub str 1 (String.length str - 2)

let mut_of_string str =
  String.sub str 0 (String.length str - 1)

}

let digit = ['0'-'9']
let lowercase_alpha = ['a'-'z']
let uppercase_alpha = ['A'-'Z']
let min = '-'

let int = digit+
let u8 = digit+ "u8"
let float = digit+ '.' digit+
let i32 = min? digit+ "i32"
let f32 = min? float "f32"

let lowercase_id = lowercase_alpha (lowercase_alpha|uppercase_alpha|digit|'_')*
let builtin_id = "__" lowercase_id

let kebab_id = lowercase_alpha (lowercase_alpha|'-'|digit|'?')*
let mut_id = (kebab_id)'&'
let keyword = ':'(lowercase_id|kebab_id)
let mut_kw = ':'(lowercase_id|kebab_id)'&'
let constructor = '#'(lowercase_id|kebab_id)
let accessor = '.'(lowercase_id|kebab_id|int)

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

rule read =
  parse
  | white    { read lexbuf }
  | newline  { next_line lexbuf; read lexbuf }
  | int      { Int (int_of_string (Lexing.lexeme lexbuf)) }
  | float    { Float (float_of_string (Lexing.lexeme lexbuf)) }
  | u8       { U8 (u8_of_string (Lexing.lexeme lexbuf)) }
  | i32      { I32 (f_of_string int_of_string (Lexing.lexeme lexbuf)) }
  | f32      { F32 (f_of_string float_of_string (Lexing.lexeme lexbuf)) }
  | "true"   { True }
  | "false"  { False }
  | "and"    { And }
  | "or"     { Or }
  | '='      { Equal }
  | "=."     { Bin_equal_f }
  | "'"      { Quote }
  | "if"     { If }
  | "else"   { Else }
  | "fun"    { Fun }
  | "val"    { Val }
  | "let"    { Let }
  | "match"  { Match }
  | "do"     { Do }
  | "open"   { Open }
  | "type" { Type }
  | "external"{ Defexternal }
  | "set"   { Set }
  | "cond"   { Cond }
  | "fmt-str"{ Fmt_str }
  | lowercase_id { Lowercase_id (Lexing.lexeme lexbuf) }
  | kebab_id { Kebab_id (Lexing.lexeme lexbuf) }
  | keyword  { Keyword (name_of_string (Lexing.lexeme lexbuf)) }
  | mut_kw   { Mut_keyword (mut_name_of_string (Lexing.lexeme lexbuf)) }
  | accessor { Accessor (name_of_string (Lexing.lexeme lexbuf)) }
  | constructor{ Constructor (name_of_string (Lexing.lexeme lexbuf)) }
  | builtin_id { Builtin_id (Lexing.lexeme lexbuf) }
  | '_'      { Wildcard }
  | '"'      { read_string (Buffer.create 17) lexbuf }
  | '&'      { Ampersand }
  | '@'      { At }
  | '+'      { Plus_i }
  | min      { Minus_i }
  | '*'      { Mult_i }
  | '/'      { Div_i }
  | "+."     { Plus_f }
  | "-."     { Minus_f }
  | "*."     { Mult_f }
  | "/."     { Div_f }
  | '<'      { Less_i }
  | "<."     { Less_f }
  | '>'      { Greater_i }
  | ">."     { Greater_f }
  | '('      { Lpar }
  | ')'      { Rpar }
  | '{'      { Lbrac }
  | '}'      { Rbrac }
  | '['      { Lbrack }
  | ']'      { Rbrack }
  | "$["     { Larray }
  | "->"     { Arrow_right }
  | "->>"    { Arrow_righter }
  | "--"     { line_comment lexbuf }
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
  | [^ '"' '\\' '\n' '\r']+
    { Buffer.add_string buf (Lexing.lexeme lexbuf);
      read_string buf lexbuf
    }
  | _ { raise (SyntaxError ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
  | eof { raise (SyntaxError ("String is not terminated")) }
