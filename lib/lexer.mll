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
}

let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']

let int = digit+
let id = alpha (alpha|digit)*

let white = [' ' '\t']+
let newline = '\r' | '\n' | "\r\n"

rule read =
  parse
  | white    { read lexbuf }
  | newline  { next_line lexbuf; read lexbuf }
  | int      { Int (int_of_string (Lexing.lexeme lexbuf)) }
  | "true"   { True }
  | "false"  { False }
  | '='      { Equal }
  | "=="     { Bin_equal }
  | ','      { Comma }
  | ':'      { Colon }
  | "if"     { If }
  | "then"   { Then }
  | "else"   { Else }
  | id       { Identifier (Lexing.lexeme lexbuf) }
  | '+'      { Plus }
  | '-'      { Minus }
  | '*'      { Mult }
  | '<'      { Less }
  | '.'      { Dot }
  | '('      { Lpar }
  | ')'      { Rpar }
  | '{'      { Lbrac }
  | '}'      { Rbrac }
  | '\\'     { Backslash }
  | "--"     { line_comment lexbuf }
  | eof      { Eof }
  | _ { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }

and line_comment =
  parse
  | newline { next_line lexbuf; read lexbuf }
  | eof     { Eof }
  | _       { line_comment lexbuf }
