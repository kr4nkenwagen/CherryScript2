package scan

import "../source_code"
import "../token"
import "../token_list"
import "../types"

consume_number :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	if src == nil do return false, .OBJECT_IS_NIL_IN_SCANNER_NUMBER

	first_char := source_code.peek(src, 0) or_return
	if first_char < '0' || first_char > '9' {
		if first_char == '.' || first_char == '-' {
			next_char := source_code.peek(src, 1) or_return
			if next_char < '0' || next_char > '9' do return
		} else do return
	}
	is_float := false
	start_position := src.pointer


	if first_char == '-' {
		second_char := source_code.peek(src, 1) or_return
		third_char := source_code.peek(src, 2) or_return

		if is_number(second_char) || (second_char == '.' && third_char != '.') {
			source_code.advance(src) or_return
		} else do return false, .UNEXPECTED_CHARACTER_IN_SCANNER_NUMBER
	}

	for !src.is_at_end {
		character := source_code.peek(src, 0) or_return
		second_char := source_code.peek(src, 1) or_return
		if character == '.' {
			if second_char == '.' do break
			if is_float do return false, .UNEXPECTED_CHARACTER_IN_LOOP_IN_SCANNER_NUMBER
			is_float = true
		}
		if is_number(second_char) || second_char == '.' {
			source_code.advance(src) or_return
		} else do break
	}
	total_length := int(src.pointer - start_position) + 1
	str := string(src.content[start_position:start_position + total_length])
	tkn := token.create(src, .NUMBER, str) or_return
	token_list.add(tkn_list, tkn) or_return
	consumed = true
	return
}
