package grammar

import "../types"

keywords: []types.grammar_t = {
	{literal = "math", id = .MATH},
	{literal = "string", id = .STRING},
	{literal = "$", id = .EXECUTE},
	{literal = "terminal", id = .TERMINAL},
	{literal = "http", id = .HTTP},
	{literal = "json", id = .JSON},
	{literal = "global", id = .GLOBAL},
	{literal = "clr", id = .CLEAR},
	{literal = "key", id = .KEY},
	{literal = "sleep", id = .SLEEP},
	{literal = "in", id = .IN},
	{literal = "time", id = .TIME},
	{literal = "var", id = .VAR},
	{literal = "true", id = .TRUE},
	{literal = "remove", id = .REMOVE},
	{literal = "rm", id = .RM},
	{literal = "return", id = .RETURN},
	{literal = "print", id = .PRINT},
	{literal = "println", id = .PRINT_LINE},
	{literal = "len", id = .LENGTH},
	{literal = "out", id = .OUT},
	{literal = "null", id = .NULL},
	{literal = "if", id = .IF},
	{literal = "fn", id = .FUNCTION},
	{literal = "false", id = .FALSE},
	{literal = "for", id = .FOR},
	{literal = "exists", id = .EXISTS},
	{literal = "elif", id = .ELSE_IF},
	{literal = "else", id = .ELSE},
	{literal = "continue", id = .CONTINUE},
	{literal = "const", id = .CONST},
	{literal = "break", id = .BREAK},
	{literal = "err", id = .ERROR},
}


unary: []types.grammar_t = {{literal = "-", id = .MINUS}}

symbols: []types.grammar_t = {
	{literal = "+=", id = .PLUS_EQUAL},
	{literal = "-=", id = .MINUS_EQUAL},
	{literal = "*=", id = .STAR_EQUAL},
	{literal = "/=", id = .SLASH_EQUAL},
	{literal = "+", id = .PLUS},
	{literal = "-", id = .MINUS},
	{literal = "*", id = .STAR},
	{literal = "/", id = .SLASH},
	{literal = "%", id = .MODULUS},
	{literal = "&&", id = .AND},
	{literal = "||", id = .OR},
	{literal = ">=", id = .GREATER_EQUAL},
	{literal = ">", id = .GREATER},
	{literal = "<=", id = .LESS_EQUAL},
	{literal = "<", id = .LESS},
	{literal = "==", id = .EQUAL_EQUAL},
	{literal = "!=", id = .BANG_EQUAL},
	{literal = "(", id = .LEFT_PAREN},
	{literal = ")", id = .RIGHT_PAREN},
	{literal = "{", id = .LEFT_BRACE},
	{literal = "}", id = .RIGHT_BRACE},
	{literal = "[", id = .LEFT_BRACKET},
	{literal = "]", id = .RIGHT_BRACKET},
	{literal = ";", id = .TERMINATOR},
	{literal = "\n", id = .TERMINATOR},
	{literal = ",", id = .COMMA},
	{literal = ".", id = .DOT},
	{literal = "=", id = .EQUAL},
	{literal = "$", id = .EXECUTE},
	{literal = "@", id = .AT},
	{literal = ":^", id = .COLON_HAT},
	{literal = ":", id = .COLON},
	{literal = "..", id = .DOT_DOT},
	{literal = "->", id = .RIGHT_ARROW},
	{literal = "<-", id = .LEFT_ARROW},
	{literal = "!", id = .BANG},
}

MODULE: string : "module"
COMMENT: rune : '#'
NEWLINE: rune : '\n'
STRING_WRAPPER: rune : '"'
CHAR_WRAPPER: rune : '\''
