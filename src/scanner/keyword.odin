package scan

import "../grammar"
import "../source_code"
import "../token"
import "../types"
import "core:unicode"

consume_keyword :: proc(
	src: ^types.source_code_t,
) -> (
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	if src == nil {
		return nil, .OBJECT_IS_NIL_IN_SCANNER_KEYWORD
	}
	if src.pointer > 0 {
		prev_char := source_code.peek(src, -1) or_return
		if unicode.is_alpha(prev_char) do return nil, .UNEXPECTED_CHARACTER_IN_SCANNER_KEYWORD
	}
	character := source_code.peek(src, 0) or_return
	switch (character) {
	case 'b':
		fallthrough
	case 'B':
		word, match := match_and_consume(src, grammar.BREAK) or_return
		if match do return token.create(src, .BREAK, word)

	case 'c':
		fallthrough
	case 'C':
		word, match := match_and_consume(src, grammar.CONST) or_return
		if match do return token.create(src, .CONST, word)

		word, match = match_and_consume(src, grammar.CONTINUE) or_return
		if match do return token.create(src, .CONTINUE, word)

		word, match = match_and_consume(src, grammar.CLEAR) or_return
		if match do return token.create(src, .CLEAR, word)

	case 'e':
		fallthrough
	case 'E':
		word, match := match_and_consume(src, grammar.ELSE) or_return
		if match do return token.create(src, .ELSE, word)

		word, match = match_and_consume(src, grammar.ELSE_IF) or_return
		if match do return token.create(src, .ELSE_IF, word)

		word, match = match_and_consume(src, grammar.ERROR) or_return
		if match do return token.create(src, .ERROR, word)

		word, match = match_and_consume(src, grammar.EXISTS) or_return
		if match do return token.create(src, .EXISTS, word)

	case 'f':
		fallthrough
	case 'F':
		word, match := match_and_consume(src, grammar.FOR) or_return
		if match do return token.create(src, .FOR, word)

		word, match = match_and_consume(src, grammar.FALSE) or_return
		if match do return token.create(src, .FALSE, word)

		word, match = match_and_consume(src, grammar.FUNCTION) or_return
		if match do return token.create(src, .FUNCTION, word)

	case 'i':
		fallthrough
	case 'I':
		word, match := match_and_consume(src, grammar.IF) or_return
		if match do return token.create(src, .IF, word)

		word, match = match_and_consume(src, grammar.IN) or_return
		if match do return token.create(src, .IN, word)

	case 'n':
		fallthrough
	case 'N':
		word, match := match_and_consume(src, grammar.NULL) or_return
		if match do return token.create(src, .NULL, word)

	case 'm':
		fallthrough
	case 'M':
		match := is_next_word_match(src, grammar.MODULE) or_return
		if match {
			word := consume_word(src) or_return
			source_code.advance(src, 2) or_return
			path := consume_string(src) or_return
			source_code.advance(src) or_return
			source_code.import_file(src, path) or_return
			return token.create(src, .TERMINATOR, "")
		}
	case 'k':
		fallthrough
	case 'K':
		word, match := match_and_consume(src, grammar.KEY) or_return
		if match do return token.create(src, .KEY, word)

	case 'o':
		fallthrough
	case 'O':
		word, match := match_and_consume(src, grammar.OUT) or_return
		if match do return token.create(src, .OUT, word)

	case 'l':
		fallthrough
	case 'L':
		word, match := match_and_consume(src, grammar.LENGTH) or_return
		if match do return token.create(src, .LENGTH, word)

	case 'j':
		fallthrough
	case 'J':
		word, match := match_and_consume(src, grammar.JSON) or_return
		if match do return token.create(src, .JSON, word)

	case 'p':
		fallthrough
	case 'P':
		word, match := match_and_consume(src, grammar.PRINT_LINE) or_return
		if match do return token.create(src, .PRINT_LINE, word)

		word, match = match_and_consume(src, grammar.POST) or_return
		if match do return token.create(src, .POST, word)

		word, match = match_and_consume(src, grammar.PRINT) or_return
		if match do return token.create(src, .PRINT, word)

		word, match = match_and_consume(src, grammar.PUT) or_return
		if match do return token.create(src, .PUT, word)


	case 's':
		fallthrough
	case 'S':
		word, match := match_and_consume(src, grammar.SLEEP) or_return
		if match do return token.create(src, .SLEEP, word)

	case 'r':
		fallthrough
	case 'R':
		word, match := match_and_consume(src, grammar.RETURN) or_return
		if match do return token.create(src, .RETURN, word)

		word, match = match_and_consume(src, grammar.FILE_REMOVE) or_return
		if match do return token.create(src, .RM, word)

		word, match = match_and_consume(src, grammar.REMOVE) or_return
		if match do return token.create(src, .REMOVE, word)

	case 't':
		fallthrough
	case 'T':
		word, match := match_and_consume(src, grammar.TRUE) or_return
		if match do return token.create(src, .TRUE, word)

		word, match = match_and_consume(src, grammar.TIME) or_return
		if match do return token.create(src, .TIME, word)
	case 'v':
		fallthrough
	case 'V':
		word, match := match_and_consume(src, grammar.VAR) or_return
		if match do return token.create(src, .VAR, word)

	case 'g':
		fallthrough
	case 'G':
		word, match := match_and_consume(src, grammar.GLOBAL) or_return
		if match do return token.create(src, .GLOBAL, word)

		word, match = match_and_consume(src, grammar.GET) or_return
		if match do return token.create(src, .GET, word)

	case '&':
		second_char := source_code.peek(src, 1) or_return
		if second_char == '&' {
			source_code.advance(src, 2) or_return
			return token.create(src, .AND, "&&")
		}

	case '|':
		second_char := source_code.peek(src, 1) or_return
		if second_char == '|' {
			source_code.advance(src, 2) or_return
			return token.create(src, .OR, "||")
		}

	case '@':
		source_code.advance(src) or_return
		file := consume_string(src) or_return
		return token.create(src, .AT, file)
	}

	return
}
