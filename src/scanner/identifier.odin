package scan

import "../source_code"
import "../token"
import "../types"
import "core:unicode"

consume_identifier :: proc(
	src: ^types.source_code_t,
) -> (
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	if src == nil do return nil, .OBJECT_IS_NIL
	prev_char := source_code.peek(src, -1) or_return
	if unicode.is_alpha(prev_char) || is_number(prev_char) do return nil, .UNEXPECTED_CHARACTER
	word := consume_word(src) or_return
	return token.create(src, .IDENTIFIER, word)
}
