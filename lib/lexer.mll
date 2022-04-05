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

}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']


let int = digit+
let u8 = digit+ "u8"
let float = digit+ '.' digit+
let id = alpha (alpha|digit|'_')*
let builtin_id = "__" id

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

rule read =
  parse
  | white    { read lexbuf }
  | newline  { next_line lexbuf; read lexbuf }
  | int      { Int (int_of_string (Lexing.lexeme lexbuf)) }
  | float    { Float (float_of_string (Lexing.lexeme lexbuf)) }
  | u8       { U8 (u8_of_string (Lexing.lexeme lexbuf)) }
  | "true"   { True }
  | "false"  { False }
  | '='      { Equal }
  | "=="     { Bin_equal }
  | ','      { Comma }
  | ':'      { Colon }
  | "'"      { Quote }
  | "if"     { If }
  | "then"   { Then }
  | "else"   { Else }
  | "elseif" { Elseif }
  | "external" { External }
  | "fun"    { Fun }
  | "type"   { Type }
  | "do"     { Do }
  | "mutable" { Mutable }
  | "end"    { End }
  | id       { Identifier (Lexing.lexeme lexbuf) }
  | builtin_id { Builtin_id (Lexing.lexeme lexbuf) }
  | '"'      { read_string (Buffer.create 17) lexbuf }
  | '+'      { Plus }
  | '-'      { Minus }
  | '*'      { Mult }
  | '<'      { Less }
  | '.'      { Dot }
  | '('      { Lpar }
  | ')'      { Rpar }
  | '{'      { Lbrac }
  | '}'      { Rbrac }
  | '['      { Lbrack }
  | ']'      { Rbrack }
  | "->"     { Arrow_right }
  | "<-"     { Arrow_left }
  | "->>"    { Pipe_tail }
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
  | '"'       { String_lit (Buffer.contents buf) }
  | '\\' '/'  { Buffer.add_char buf '/'; read_string buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; read_string buf lexbuf }
  | '\\' 'b'  { Buffer.add_char buf '\b'; read_string buf lexbuf }
  | '\\' 'f'  { Buffer.add_char buf '\012'; read_string buf lexbuf }
  | '\\' 'n'  { Buffer.add_char buf '\n'; read_string buf lexbuf }
  | '\\' 'r'  { Buffer.add_char buf '\r'; read_string buf lexbuf }
  | '\\' 't'  { Buffer.add_char buf '\t'; read_string buf lexbuf }
  | [^ '"' '\\']+
    { Buffer.add_string buf (Lexing.lexeme lexbuf);
      read_string buf lexbuf
    }
  | _ { raise (SyntaxError ("Illegal string character: " ^ Lexing.lexeme lexbuf)) }
  | eof { raise (SyntaxError ("String is not terminated")) }
