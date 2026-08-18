package scan

import "../grammar"
import "../source_code"
import "../types"

consume_comment :: proc(src: ^types.source_code_t) -> (code: types.exit_codes) {
	if src == nil do return .OBJECT_IS_NIL
	char := source_code.peek(src, 0) or_return
	if char != grammar.COMMENT do return .UNEXPECTED_CHARACTER
	for !src.is_at_end {
		c := source_code.advance(src) or_return
		if c == grammar.NEWLINE || c == grammar.COMMENT do return .OK
	}
	return .OK
}
