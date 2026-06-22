package token

import "../source_code"
import "core:fmt"

type_t :: enum {
	LEFT_PAREN,
	RIGHT_PAREN,
	LEFT_BRACE,
	RIGHT_BRACE,
	COMMA,
	DOT,
	MINUS,
	PLUS,
	SEMICOLON,
	SLASH,
	STAR,
	BANG,
	EQUAL,
	GREATER,
	LESS,
	COMMENT,
	MODULUS,
	TERMINATOR,
	COLON,
	BANG_EQUAL,
	GREATER_EQUAL,
	LESS_EQUAL,
	EQUAL_EQUAL,
	COLON_HAT,
	DOT_DOT,
	STRING_WRAPPER,
	NUMBER,
	AND,
	CLASS,
	ELSE,
	FALSE,
	FUNCTION,
	FOR,
	IF,
	NIL,
	OR,
	PRINT,
	RETURN,
	SUPER,
	THIS,
	TRUE,
	VAR,
	WHILE,
	END_OF_FILE,
	IDENTIFIER,
	CONST,
	LEFT_BRACKET,
	RIGHT_BRACKET,
	ELSE_IF,
	PLUS_EQUAL,
	MINUS_EQUAL,
	STAR_EQUAL,
	SLASH_EQUAL,
	SOFT_TERMINATOR,
	PRINT_LINE,
	CONTINUE,
	BREAK,
	IMPORT,
	OUT,
	ERROR,
	REMOVE,
	UNKNOWN_TOKEN,
}

token_t :: struct {
	type:    type_t,
	literal: string,
	column:  int,
	line:    int,
}

create :: proc(src: ^source_code.source_code_t, type: type_t, literal: string) -> ^token_t {
	if src == nil || type == nil {
		return nil
	}

	token := new(token_t)
	token.literal = literal
	token.column = src.column
	token.line = src.line
	token.type = type
	return token
}

generate_unknown_token :: proc() -> ^token_t {
	token := new(token_t)
	token.type = type_t.UNKNOWN_TOKEN
	return token
}
