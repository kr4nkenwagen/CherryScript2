package scan

import "../grammar"
import "../source_code"
import "../sys"
import "../token"
import "../token_list"
import "../types"
import "core:strings"
import "core:unicode"

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

consume_reserved_word :: proc(
	src: ^types.source_code_t,
) -> (
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	if src.pointer > 0 {
		prev_char := source_code.peek(src, -1) or_return
		if unicode.is_alpha(prev_char) do return nil, .UNEXPECTED_CHARACTER
	}
	character := source_code.peek(src, 0) or_return
	switch (character) {
	case 'b':
		fallthrough
	case 'B':
		word, match := match_and_consume(src, grammar.BREAK) or_return
		if match do return token.create(src, .BREAK, word)

	case 'c':
		fallthrough
	case 'C':
		word, match := match_and_consume(src, grammar.CONST) or_return
		if match do return token.create(src, .CONST, word)

		word, match = match_and_consume(src, grammar.CONTINUE) or_return
		if match do return token.create(src, .CONTINUE, word)

		word, match = match_and_consume(src, grammar.CLEAR) or_return
		if match do return token.create(src, .CLEAR, word)

	case 'e':
		fallthrough
	case 'E':
		word, match := match_and_consume(src, grammar.ELSE) or_return
		if match do return token.create(src, .ELSE, word)

		word, match = match_and_consume(src, grammar.ELSE_IF) or_return
		if match do return token.create(src, .ELSE_IF, word)

		word, match = match_and_consume(src, grammar.ERROR) or_return
		if match do return token.create(src, .ERROR, word)

		word, match = match_and_consume(src, grammar.EXISTS) or_return
		if match do return token.create(src, .EXISTS, word)

	case 'f':
		fallthrough
	case 'F':
		word, match := match_and_consume(src, grammar.FOR) or_return
		if match do return token.create(src, .FOR, word)

		word, match = match_and_consume(src, grammar.FALSE) or_return
		if match do return token.create(src, .FALSE, word)

		word, match = match_and_consume(src, grammar.FUNCTION) or_return
		if match do return token.create(src, .FUNCTION, word)

	case 'i':
		fallthrough
	case 'I':
		word, match := match_and_consume(src, grammar.IF) or_return
		if match do return token.create(src, .IF, word)

		word, match = match_and_consume(src, grammar.IN) or_return
		if match do return token.create(src, .IN, word)

	case 'n':
		fallthrough
	case 'N':
		word, match := match_and_consume(src, grammar.NULL) or_return
		if match do return token.create(src, .NULL, word)

	case 'm':
		fallthrough
	case 'M':
		match := is_next_word_match(src, grammar.MODULE) or_return
		if match {
			word := consume_word(src) or_return
			source_code.advance(src, 2) or_return
			path := consume_string(src) or_return
			source_code.advance(src) or_return
			source_code.import_file(src, path) or_return
			return token.create(src, .TERMINATOR, "")
		}
	case 'k':
		fallthrough
	case 'K':
		word, match := match_and_consume(src, grammar.KEY) or_return
		if match do return token.create(src, .KEY, word)

	case 'o':
		fallthrough
	case 'O':
		word, match := match_and_consume(src, grammar.OUT) or_return
		if match do return token.create(src, .OUT, word)

	case 'l':
		fallthrough
	case 'L':
		word, match := match_and_consume(src, grammar.LENGTH) or_return
		if match do return token.create(src, .LENGTH, word)

	case 'j':
		fallthrough
	case 'J':
		word, match := match_and_consume(src, grammar.JSON) or_return
		if match do return token.create(src, .JSON, word)

	case 'p':
		fallthrough
	case 'P':
		word, match := match_and_consume(src, grammar.PRINT_LINE) or_return
		if match do return token.create(src, .PRINT_LINE, word)

		word, match = match_and_consume(src, grammar.PRINT) or_return
		if match {
			word := consume_word(src) or_return
			return token.create(src, .PRINT, word)
		}

	case 's':
		fallthrough
	case 'S':
		word, match := match_and_consume(src, grammar.SLEEP) or_return
		if match do return token.create(src, .SLEEP, word)

	case 'r':
		fallthrough
	case 'R':
		word, match := match_and_consume(src, grammar.RETURN) or_return
		if match do return token.create(src, .RETURN, word)

		word, match = match_and_consume(src, grammar.FILE_REMOVE) or_return
		if match do return token.create(src, .RM, word)

		word, match = match_and_consume(src, grammar.REMOVE) or_return
		if match do return token.create(src, .REMOVE, word)

	case 't':
		fallthrough
	case 'T':
		word, match := match_and_consume(src, grammar.TRUE) or_return
		if match do return token.create(src, .TRUE, word)

		word, match = match_and_consume(src, grammar.TIME) or_return
		if match do return token.create(src, .TIME, word)
	case 'v':
		fallthrough
	case 'V':
		word, match := match_and_consume(src, grammar.VAR) or_return
		if match do return token.create(src, .VAR, word)

	case 'w':
		fallthrough
	case 'W':
		word, match := match_and_consume(src, grammar.WHILE) or_return
		if match do return token.create(src, .WHILE, word)

	case 'g':
		fallthrough
	case 'G':
		word, match := match_and_consume(src, grammar.GLOBAL) or_return
		if match do return token.create(src, .GLOBAL, word)

		word, match = match_and_consume(src, grammar.GET) or_return
		if match do return token.create(src, .GET, word)

	case '&':
		second_char := source_code.peek(src, 1) or_return
		if second_char == '&' {
			source_code.advance(src, 2) or_return
			return token.create(src, .AND, "&&")
		}

	case '|':
		second_char := source_code.peek(src, 1) or_return
		if second_char == '|' {
			source_code.advance(src, 2) or_return
			return token.create(src, .OR, "||")
		}

	case '@':
		source_code.advance(src) or_return
		file := consume_string(src) or_return
		return token.create(src, .AT, file)
	}

	return nil, .OK
}

run :: proc(src: ^types.source_code_t) -> (tkn_list: ^types.token_list_t, code: types.exit_codes) {
	if src == nil do return nil, .OBJECT_IS_NIL
	list := token_list.create() or_return
	for !src.is_at_end {
		tmp := (list.length > 0) ? list.list[list.length - 1] : nil
		character, character_err := source_code.advance(src)
		if character_err != .EOF_IN_SOURCE_CODE_REACHED {
			if sys.is_error(character_err) do return nil, character_err
		}
		switch (character) {
		case '(':
			tok := token.create(src, .LEFT_PAREN, "(") or_return
			token_list.add(list, tok) or_return

		case ')':
			tok := token.create(src, .RIGHT_PAREN, ")") or_return
			token_list.add(list, tok) or_return

		case '{':
			tok := token.create(src, .LEFT_BRACE, "{") or_return
			token_list.add(list, tok) or_return

		case '}':
			if tmp == nil do break
			if tmp.type != .TERMINATOR {
				tok := token.create(src, .TERMINATOR, ";") or_return
				token_list.add(list, tok) or_return
			}

			tok := token.create(src, .RIGHT_BRACE, "}") or_return
			token_list.add(list, tok) or_return

		case '[':
			tok := token.create(src, .LEFT_BRACKET, "[") or_return
			token_list.add(list, tok) or_return

		case ']':
			tok := token.create(src, .RIGHT_BRACKET, "]") or_return
			token_list.add(list, tok) or_return

		case ',':
			tok := token.create(src, .COMMA, ",") or_return
			token_list.add(list, tok) or_return

		case ':':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '^' {
				tok := token.create(src, .COLON_HAT, ":^") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .COLON, ":") or_return
				token_list.add(list, tok) or_return
			}

		case '.':
			second_char := source_code.peek(src, 1) or_return
			if is_number(second_char) {
				number := consume_number(src) or_return
				tok := token.create(src, .NUMBER, number) or_return
				token_list.add(list, tok) or_return

			} else if second_char == '.' {
				tok := token.create(src, .DOT_DOT, "..") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .DOT, ".") or_return
				token_list.add(list, tok) or_return
			}

		case '-':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .MINUS_EQUAL, "-=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else if second_char == '>' {
				tok := token.create(src, .RIGHT_ARROW, "->") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else if is_number(second_char) || second_char == '.' {
				is_unary := true
				if tmp != nil {
					#partial switch tmp.type {
					case .IDENTIFIER, .NUMBER, .RIGHT_PAREN, .RIGHT_BRACKET, .RIGHT_BRACE:
						is_unary = false
					case:
						is_unary = true
					}
				}
				if is_unary {
					third_char := source_code.peek(src, 2) or_return
					if is_number(second_char) || (second_char == '.' && third_char != '.') {
						number := consume_number(src) or_return
						tok := token.create(src, .NUMBER, number) or_return
						token_list.add(list, tok) or_return
						break
					}
				}
				tok := token.create(src, .MINUS, "-") or_return
				token_list.add(list, tok) or_return

			} else {
				tok := token.create(src, .MINUS, "-") or_return
				token_list.add(list, tok) or_return
			}

		case '+':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .PLUS_EQUAL, "+=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .PLUS, "+") or_return
				token_list.add(list, tok) or_return
			}

		case '%':
			tok := token.create(src, .MODULUS, "%") or_return
			token_list.add(list, tok) or_return

		case '/':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .SLASH_EQUAL, "/=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .SLASH, "/") or_return
				token_list.add(list, tok) or_return
			}

		case '*':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .STAR_EQUAL, "*=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .STAR, "*") or_return
				token_list.add(list, tok) or_return
			}

		case '\'':
			fallthrough
		case '"':
			str := consume_string(src) or_return
			tok := token.create(src, .STRING_WRAPPER, str) or_return
			token_list.add(list, tok) or_return

		case '!':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .BANG_EQUAL, "!=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .BANG, "!") or_return
				token_list.add(list, tok) or_return
			}

		case '=':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .EQUAL_EQUAL, "==") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .EQUAL, "=") or_return
				token_list.add(list, tok) or_return
			}

		case '>':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .GREATER_EQUAL, ">=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .GREATER, ">") or_return
				token_list.add(list, tok) or_return
			}

		case '<':
			second_char := source_code.peek(src, 1) or_return
			if second_char == '=' {
				tok := token.create(src, .LESS_EQUAL, "<=") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else if second_char == '-' {
				tok := token.create(src, .LEFT_ARROW, "<-") or_return
				token_list.add(list, tok) or_return
				source_code.advance(src) or_return

			} else {
				tok := token.create(src, .LESS, "<") or_return
				token_list.add(list, tok) or_return
			}

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
			number := consume_number(src) or_return
			tok := token.create(src, .NUMBER, number) or_return
			token_list.add(list, tok) or_return

		case '\n':
			if tmp == nil do break
			if tmp.type == .LEFT_PAREN || tmp.type == .TERMINATOR || tmp.type == .LEFT_BRACE do break

			fallthrough
		case ';':
			tok := token.create(src, .TERMINATOR, ";") or_return
			token_list.add(list, tok) or_return

		case '\t':
		case ' ':
		case '#':
			consume_comment(src) or_return
		case:
			if src.is_at_end do break
			if src.content[src.pointer] == 0 do break
			res_word, err := consume_reserved_word(src)
			if sys.is_error(err) && err != .PEEK_OUT_OF_BOUNDS do return nil, err

			if res_word == nil {
				word, word_err := consume_identifier(src)
				if sys.is_error(word_err) && word_err != .PEEK_OUT_OF_BOUNDS do return nil, word_err
				if len(word.literal) > 0 do token_list.add(list, word) or_return
			} else {
				token_list.add(list, res_word) or_return
			}
		}
	}
	term_char := token_list.peek(list, 0) or_return
	if term_char.type != .TERMINATOR {
		tok := token.create(src, .TERMINATOR, ";") or_return
		token_list.add(list, tok) or_return
	}

	tok := token.create(src, .END_OF_FILE, "EOF") or_return
	token_list.add(list, tok) or_return
	return list, .OK
}
