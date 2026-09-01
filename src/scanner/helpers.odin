package scan

import "../grammar"
import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:sort"
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
	return
}

consume_word :: proc(
	src: ^types.source_code_t,
) -> (
	consumed_word: string,
	code: types.exit_codes,
) {
	if src == nil do return "", .OBJECT_IS_NIL_IN_SCANNER_CONSUME_WORD
	start_position := src.pointer
	for !src.is_at_end {
		next_char := source_code.peek(src, 1) or_return
		if is_end_of_word(next_char) do break
		source_code.advance(src) or_return
	}
	total_length := int(src.pointer - start_position) + 1
	if total_length <= 0 do return "", .WORD_NOT_FOUND_IN_SCANNER_CONSUME_WORD
	consumed_word = string(src.content[start_position:start_position + total_length])
	return
}

is_next_word_match :: proc(
	src: ^types.source_code_t,
	word: string,
) -> (
	next_word_match: bool,
	code: types.exit_codes,
) {
	if src == nil do return false, .OBJECT_IS_NIL_IN_SCANNER_IS_NEXT_WORD_MATCH
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
		if is_alphanum do return
	}
	next_word_match = true
	return
}

order_symbols_by_literal_length :: proc() {
	ordered := make([]types.grammar_t, len(grammar.symbols))
	copy(ordered[:], grammar.symbols)
	sort.quick_sort_proc(ordered, proc(a, b: types.grammar_t) -> int {
		la, lb := len(a.literal), len(b.literal)
		if la > lb do return -1
		if la < lb do return +1
		return 0
	})
	grammar.symbols = ordered
}

append_list_tail :: proc(tkn_list: ^types.token_list_t) -> (code: types.exit_codes) {
	term_char := token_list.peek(tkn_list, 0) or_return
	if term_char.type != .TERMINATOR {
		tok := token.create(nil, .TERMINATOR, ";") or_return
		token_list.add(tkn_list, tok) or_return
	}
	tok := token.create(nil, .END_OF_FILE, "EOF") or_return
	token_list.add(tkn_list, tok) or_return

	return
}


remove_dupe_terminators :: proc(tkn_list: ^types.token_list_t) -> (code: types.exit_codes) {
	if tkn_list == nil || tkn_list.list == nil {
		if tkn_list != nil do tkn_list.length = 0
		return
	}
	write := 0
	for read := 0; read < len(tkn_list.list); read += 1 {
		if write > 0 &&
		   tkn_list.list[read].type == .TERMINATOR &&
		   tkn_list.list[write - 1].type == .TERMINATOR {
			continue
		}
		tkn_list.list[write] = tkn_list.list[read]
		write += 1
	}
	resize(&tkn_list.list, write)
	tkn_list.length = write
	return
}
