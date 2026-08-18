package scan

import "../source_code"
import "../types"
import "core:strings"

is_number :: proc(character: rune) -> (is_number: bool) {
	switch (character) {
	case '0':
		fallthrough
	case '1':
		fallthrough
	case '2':
		fallthrough
	case '3':
		fallthrough
	case '4':
		fallthrough
	case '5':
		fallthrough
	case '6':
		fallthrough
	case '7':
		fallthrough
	case '8':
		fallthrough
	case '9':
		return true
	}
	return false
}

is_end_of_word :: proc(character: rune) -> (at_end_of_word: bool) {
	switch (character) {
	case '\n':
		fallthrough
	case '\t':
		fallthrough
	case ' ':
		fallthrough
	case ';':
		fallthrough
	case '[':
		fallthrough
	case ']':
		fallthrough
	case '(':
		fallthrough
	case ')':
		fallthrough
	case '{':
		fallthrough
	case '}':
		fallthrough
	case ':':
		fallthrough
	case '=':
		fallthrough
	case '+':
		fallthrough
	case '-':
		fallthrough
	case '/':
		fallthrough
	case '*':
		fallthrough
	case '!':
		fallthrough
	case '<':
		fallthrough
	case '>':
		fallthrough
	case '.':
		fallthrough
	case ',':
		return true
	}
	return false
}

match_and_consume :: proc(
	src: ^types.source_code_t,
	match_word: string,
) -> (
	matched_word: string,
	is_matched: bool,
	code: types.exit_codes,
) {
	match := is_next_word_match(src, match_word) or_return
	if match {
		word := consume_word(src) or_return
		return word, true, .OK
	}
	return "", false, .OK
}

consume_word :: proc(
	src: ^types.source_code_t,
) -> (
	consumed_word: string,
	code: types.exit_codes,
) {
	if src == nil do return "", .OBJECT_IS_NIL
	start_position := src.pointer
	for !src.is_at_end {
		next_char := source_code.peek(src, 1) or_return
		if is_end_of_word(next_char) do break
		source_code.advance(src) or_return
	}
	total_length := int(src.pointer - start_position) + 1
	if total_length <= 0 do return "", .WORD_NOT_FOUND
	word := string(src.content[start_position:start_position + total_length])
	return word, .OK
}

is_next_word_match :: proc(
	src: ^types.source_code_t,
	word: string,
) -> (
	next_word_match: bool,
	code: types.exit_codes,
) {
	if src == nil do return false, .OBJECT_IS_NIL
	end_idx := src.pointer + len(word)
	if end_idx > src.length do return false, .OK
	sliced := src.content[src.pointer:end_idx]
	if !strings.equal_fold(sliced, word) do return false, .OK
	if end_idx < src.length {
		next_char := src.content[end_idx]
		is_alphanum :=
			(next_char >= 'a' && next_char <= 'z') ||
			(next_char >= 'A' && next_char <= 'Z') ||
			(next_char >= '0' && next_char <= '9') ||
			next_char == '_'
		if is_alphanum do return false, .OK
	}
	return true, .OK
}
