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
		if prev_char == '.' do return nil, .OK
	}
	for i := 0; i < len(grammar.keywords); i += 1 {
		if grammar.keywords[i].id == .IMPORT {
			match := is_next_word_match(src, grammar.keywords[i].literal) or_return
			if match {
				word := consume_word(src) or_return
				source_code.advance(src, 2) or_return
				path := consume_string(src) or_return
				source_code.advance(src) or_return
				source_code.import_file(src, path) or_return
				return token.create(src, .TERMINATOR, "")
			}
		}
		word, match := match_and_consume(src, grammar.keywords[i].literal) or_return
		if match do return token.create(src, grammar.keywords[i].id, word)

	}
	character := source_code.peek(src, 0) or_return
	switch (character) {
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
