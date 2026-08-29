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
	{literal = "module", id = .IMPORT},
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
}

logical: []types.grammar_t = {{literal = "&&", id = .AND}, {literal = "||", id = .OR}}

equality: []types.grammar_t = {
	{literal = "==", id = .EQUAL_EQUAL},
	{literal = "!=", id = .BANG_EQUAL},
}

comparers: []types.grammar_t = {
	{literal = ">", id = .GREATER},
	{literal = ">=", id = .GREATER_EQUAL},
	{literal = "<", id = .LESS},
	{literal = "<=", id = .LESS_EQUAL},
}

operators: []types.grammar_t = {
	{literal = "+", id = .PLUS},
	{literal = "-", id = .MINUS},
	{literal = "*", id = .STAR},
	{literal = "/", id = .SLASH},
	{literal = "%", id = .MODULUS},
}

unary: []types.grammar_t = {{literal = "!", id = .BANG}, {literal = "-", id = .MINUS}}

COMMENT: rune : '#'
NEWLINE: rune : '\n'
STRING_WRAPPER: rune : '"'
CHAR_WRAPPER: rune : '\''
