package scan

import "../grammar"
import "../source_code"
import "../types"

consume_string :: proc(
	src: ^types.source_code_t,
) -> (
	consumed_string: string,
	code: types.exit_codes,
) {
	if src == nil do return "", .OBJECT_IS_NIL
	start_char := source_code.peek(src, 0) or_return
	if start_char != grammar.CHAR_WRAPPER && start_char != grammar.STRING_WRAPPER do return "", .UNEXPECTED_CHARACTER
	exit_char :=
		start_char == grammar.STRING_WRAPPER ? grammar.STRING_WRAPPER : grammar.CHAR_WRAPPER
	size := int(1)
	is_closed := false
	for ; src.pointer + size <= src.length; size += 1 {
		char := source_code.peek(src, size) or_return
		if char == exit_char {
			is_closed = true
			break
		}
	}
	if !is_closed do return "", .EOF_IN_STRING
	size -= 1
	for i := 0; i < size + 1; i += 1 {
		source_code.advance(src) or_return
	}
	return src.content[src.pointer - size:src.pointer], .OK
}
