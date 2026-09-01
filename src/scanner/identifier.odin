package scan

import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:unicode"

consume_identifier :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	if src == nil do return false, .OBJECT_IS_NIL_IN_SCANNER_IDENTIFIER
	if src.pointer > 0 {
		prev_char := source_code.peek(src, -1) or_return
		if unicode.is_alpha(prev_char) || is_number(prev_char) do return false, .UNEXPECTED_CHARACTER_IN_SCANNER_IDENTIFIER
	}
	consumed = true
	word := consume_word(src) or_return
	tkn := token.create(src, .IDENTIFIER, word) or_return
	token_list.add(tkn_list, tkn) or_return
	tmp, _ := source_code.peek(src)
	return
}
