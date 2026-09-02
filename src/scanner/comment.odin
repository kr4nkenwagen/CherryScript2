package scan

import "../grammar"
import "../source_code"
import "../types"

consume_comment :: proc(src: ^types.source_code_t) -> (consumed: bool, code: types.exit_codes) {
	if src == nil do return false, .OBJECT_IS_NIL_IN_SCANNER_COMMENT
	char := source_code.peek(src, 0) or_return
	if char == ' ' || char == '\t' || char == '\r' {
		consumed = true
		return
	}
	if char != grammar.COMMENT do return false, .OK
	consumed = true
	for src.pointer + 1 < src.length {
		c := source_code.peek(src, 1) or_return
		if c == grammar.NEWLINE || c == grammar.COMMENT do return
		source_code.advance(src) or_return
	}
	return
}
