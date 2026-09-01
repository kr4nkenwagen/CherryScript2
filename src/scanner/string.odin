package scan

import "../grammar"
import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:strings"

consume_string :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	c := source_code.peek(src) or_return
	if c != grammar.STRING_WRAPPER && c != grammar.CHAR_WRAPPER {
		return
	}
	consumed = true
	str := extract_string(src) or_return
	tkn := token.create(src, .STRING_WRAPPER, str) or_return
	token_list.add(tkn_list, tkn) or_return
	return
}

extract_string :: proc(src: ^types.source_code_t) -> (str: string, code: types.exit_codes) {
	if src == nil do return "", .OBJECT_IS_NIL_IN_SCANNER_STRING
	start_char := source_code.peek(src, 0) or_return
	if start_char != grammar.CHAR_WRAPPER && start_char != grammar.STRING_WRAPPER do return "", .UNEXPECTED_CHARACTER_IN_SCANNER_STRING
	exit_char :=
		start_char == grammar.STRING_WRAPPER ? grammar.STRING_WRAPPER : grammar.CHAR_WRAPPER
	size := int(1)
	is_closed := false
	is_escaped := false
	b := strings.builder_make()
	for ; src.pointer + size <= src.length; size += 1 {
		char := source_code.peek(src, size) or_return
		if is_escaped {
			is_escaped = false
			switch char {
			case 'n':
				strings.write_byte(&b, '\n')
			case 't':
				strings.write_byte(&b, '\t')
			case 'r':
				strings.write_byte(&b, '\r')
			case '0':
				strings.write_byte(&b, '\x00')
			case '\\':
				strings.write_byte(&b, '\\')
			case '"':
				strings.write_byte(&b, '"')
			case '\'':
				strings.write_byte(&b, '\'')
			case:
				strings.write_byte(&b, u8(char))
			}
			continue
		}
		if char == '\\' {
			is_escaped = true
			continue
		}
		if char == exit_char {
			is_closed = true
			break
		}
		strings.write_byte(&b, u8(char))
	}
	if !is_closed {
		strings.builder_destroy(&b)
		return "", .EOF_IN_STRING_IN_SCANNER_STRING
	}
	for i := 0; i < size; i += 1 {
		source_code.advance(src) or_return
	}
	str = strings.to_string(b)
	return
}
