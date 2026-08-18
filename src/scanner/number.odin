package scan

import "../source_code"
import "../types"


consume_number :: proc(
	src: ^types.source_code_t,
) -> (
	consumed_number: string,
	code: types.exit_codes,
) {
	if src == nil do return "", .OBJECT_IS_NIL
	is_float := false
	start_position := src.pointer

	first_char := source_code.peek(src, 0) or_return

	if first_char == '-' {
		second_char := source_code.peek(src, 1) or_return
		third_char := source_code.peek(src, 2) or_return

		if is_number(second_char) || (second_char == '.' && third_char != '.') {
			source_code.advance(src) or_return
		} else do return "", .UNEXPECTED_CHARACTER
	}

	for !src.is_at_end {
		character := source_code.peek(src, 0) or_return
		second_char := source_code.peek(src, 1) or_return
		if character == '.' {
			if second_char == '.' do break
			if is_float do return "", .UNEXPECTED_CHARACTER
			is_float = true
		}
		if is_number(second_char) || second_char == '.' {
			source_code.advance(src) or_return
		} else do break
	}
	total_length := int(src.pointer - start_position) + 1
	result := string(src.content[start_position:start_position + total_length])
	return result, .OK
}
