package grammar

import "../types"

keywords: []types.grammar_t = {
	{literal = "math", type = .MATH},
	{literal = "string", type = .STRING},
	{literal = "$", type = .EXECUTE},
	{literal = "terminal", type = .TERMINAL},
	{literal = "http", type = .HTTP},
	{literal = "json", type = .JSON},
	{literal = "global", type = .GLOBAL},
	{literal = "clr", type = .CLEAR},
	{literal = "key", type = .KEY},
	{literal = "sleep", type = .SLEEP},
	{literal = "in", type = .IN},
	{literal = "time", type = .TIME},
	{literal = "var", type = .VAR},
	{literal = "true", type = .TRUE},
	{literal = "remove", type = .REMOVE},
	{literal = "rm", type = .RM},
	{literal = "return", type = .RETURN},
	{literal = "print", type = .PRINT},
	{literal = "println", type = .PRINT_LINE},
	{literal = "len", type = .LENGTH},
	{literal = "out", type = .OUT},
	{literal = "null", type = .NULL},
	{literal = "if", type = .IF},
	{literal = "fn", type = .FUNCTION},
	{literal = "false", type = .FALSE},
	{literal = "for", type = .FOR},
	{literal = "exists", type = .EXISTS},
	{literal = "elif", type = .ELSE_IF},
	{literal = "else", type = .ELSE},
	{literal = "continue", type = .CONTINUE},
	{literal = "const", type = .CONST},
	{literal = "break", type = .BREAK},
	{literal = "err", type = .ERROR},
}


unary: []types.grammar_t = {{literal = "-", type = .MINUS}}

symbols: []types.grammar_t = {
	{literal = "+=", type = .PLUS_EQUAL},
	{literal = "-=", type = .MINUS_EQUAL},
	{literal = "*=", type = .STAR_EQUAL},
	{literal = "/=", type = .SLASH_EQUAL},
	{literal = "+", type = .PLUS},
	{literal = "-", type = .MINUS},
	{literal = "*", type = .STAR},
	{literal = "/", type = .SLASH},
	{literal = "%", type = .MODULUS},
	{literal = "&&", type = .AND},
	{literal = "||", type = .OR},
	{literal = ">=", type = .GREATER_EQUAL},
	{literal = ">", type = .GREATER},
	{literal = "<=", type = .LESS_EQUAL},
	{literal = "<", type = .LESS},
	{literal = "==", type = .EQUAL_EQUAL},
	{literal = "!=", type = .BANG_EQUAL},
	{literal = "(", type = .LEFT_PAREN},
	{literal = ")", type = .RIGHT_PAREN},
	{literal = "{", type = .LEFT_BRACE},
	{literal = "}", type = .RIGHT_BRACE},
	{literal = "[", type = .LEFT_BRACKET},
	{literal = "]", type = .RIGHT_BRACKET},
	{literal = ";", type = .TERMINATOR},
	{literal = "\n", type = .TERMINATOR},
	{literal = ",", type = .COMMA},
	{literal = ".", type = .DOT},
	{literal = "=", type = .EQUAL},
	{literal = "$", type = .EXECUTE},
	{literal = "@", type = .AT},
	{literal = ":^", type = .COLON_HAT},
	{literal = ":", type = .COLON},
	{literal = "..", type = .DOT_DOT},
	{literal = "->", type = .RIGHT_ARROW},
	{literal = "<-", type = .LEFT_ARROW},
	{literal = "!", type = .BANG},
}

MODULE: string : "module"
COMMENT: rune : '#'
NEWLINE: rune : '\n'
STRING_WRAPPER: rune : '"'
CHAR_WRAPPER: rune : '\''
