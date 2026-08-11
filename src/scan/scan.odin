package scan

import "../grammar"
import "../source_code"
import "../sys"
import "../token"
import "../token_list"
import "../types"
import "core:strings"
import "core:unicode"

consume_comment :: proc(src: ^types.source_code_t) -> types.exit_codes {
	if src == nil {
		return .OBJECT_IS_NIL
	}
	char, peek_err := source_code.peek(src, 0)
	if char != grammar.COMMENT {
		return .UNEXPECTED_CHARACTER
	}
	if sys.is_error(peek_err) {
		return peek_err
	}
	for !src.is_at_end {
		c, adv_err := source_code.advance(src)
		if sys.is_error(adv_err) {
			return adv_err
		}
		if c == grammar.NEWLINE || c == grammar.COMMENT {
			return .OK
		}
	}
	return .OK
}

consume_string :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil {
		return "", .OBJECT_IS_NIL
	}
	start_char, peek_err := source_code.peek(src, 0)
	if sys.is_error(peek_err) {
		return "", peek_err
	}
	if start_char != grammar.CHAR_WRAPPER && start_char != grammar.STRING_WRAPPER {
		return "", .UNEXPECTED_CHARACTER
	}
	exit_char :=
		start_char == grammar.STRING_WRAPPER ? grammar.STRING_WRAPPER : grammar.CHAR_WRAPPER
	size := int(1)
	is_closed := false
	for ; src.pointer + size <= src.length; size += 1 {
		char, err := source_code.peek(src, size)
		if sys.is_error(err) {
			return "", err
		}
		if char == exit_char {
			is_closed = true
			break
		}
	}
	if !is_closed {
		return "", .EOF_IN_STRING
	}
	size -= 1
	for i := 0; i < size + 1; i += 1 {
		_, err := source_code.advance(src)
		if sys.is_error(err) {
			return "", err
		}
	}
	return src.content[src.pointer - size:src.pointer], .OK
}

is_number :: proc(character: rune) -> bool {
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

is_end_of_word :: proc(character: rune) -> bool {
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

consume_word :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil {
		return "", .OBJECT_IS_NIL
	}
	start_position := src.pointer
	for !src.is_at_end {
		next_char, next_char_err := source_code.peek(src, 1)
		if sys.is_error(next_char_err) {
			return "", next_char_err
		}
		if is_end_of_word(next_char) {
			break
		}
		_, err := source_code.advance(src)
		if sys.is_error(err) {
			return "", err
		}
	}
	total_length := int(src.pointer - start_position) + 1
	if total_length <= 0 {
		return "", .WORD_NOT_FOUND
	}
	word := string(src.content[start_position:start_position + total_length])
	return word, .OK
}

consume_number :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil {
		return "", .OBJECT_IS_NIL
	}
	is_float := false
	start_position := src.pointer
	for !src.is_at_end {
		character, peek_err := source_code.peek(src, 0)
		if sys.is_error(peek_err) {
			return "", peek_err
		}
		second_char, err := source_code.peek(src, 1)
		if sys.is_error(err) && err != .PEEK_OUT_OF_BOUNDS {
			return "", err
		}
		if character == '.' {
			if second_char == '.' {
				break
			}
			if is_float {
				return "", .UNEXPECTED_CHARACTER
			}
			is_float = true
		}
		if is_number(second_char) || second_char == '.' {
			_, adv_err := source_code.advance(src)
			if sys.is_error(adv_err) {
				return "", adv_err
			}
		} else {
			break
		}
	}
	total_length := int(src.pointer - start_position) + 1
	result := string(src.content[start_position:start_position + total_length])
	return result, .OK
}

is_next_word_match :: proc(src: ^types.source_code_t, word: string) -> (bool, types.exit_codes) {
	if src == nil {
		return false, .OBJECT_IS_NIL
	}
	end_idx := src.pointer + len(word)
	if end_idx > src.length {
		return false, .OK
	}
	sliced := src.content[src.pointer:end_idx]
	if !strings.equal_fold(sliced, word) {
		return false, .OK
	}
	if end_idx < src.length {
		next_char := src.content[end_idx]
		is_alphanum :=
			(next_char >= 'a' && next_char <= 'z') ||
			(next_char >= 'A' && next_char <= 'Z') ||
			(next_char >= '0' && next_char <= '9') ||
			next_char == '_'
		if is_alphanum {
			return false, .OK
		}
	}
	return true, .OK
}

consume_identifier :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	prev_char, peek_err := source_code.peek(src, -1)
	if sys.is_error(peek_err) {
		return nil, peek_err
	}
	if unicode.is_alpha(prev_char) || is_number(prev_char) {
		return nil, .UNEXPECTED_CHARACTER
	}
	word, err := consume_word(src)
	if sys.is_error(err) {
		return nil, err
	}
	return token.create(src, .IDENTIFIER, word)
}

match_and_consume :: proc(
	src: ^types.source_code_t,
	match_word: string,
) -> (
	string,
	bool,
	types.exit_codes,
) {
	match, err := is_next_word_match(src, match_word)
	if sys.is_error(err) {
		return "", false, err
	}
	if match {
		word, match_err := consume_word(src)
		if sys.is_error(match_err) {
			return "", false, match_err
		}
		return word, true, .OK
	}
	return "", false, .OK
}

consume_reserved_word :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	if src.pointer > 0 {
		prev_char, prev_char_err := source_code.peek(src, -1)
		if sys.is_error(prev_char_err) && prev_char_err != .PEEK_OUT_OF_BOUNDS {
			return nil, prev_char_err
		}
		if unicode.is_alpha(prev_char) {
			return nil, .UNEXPECTED_CHARACTER
		}
	}
	character, peek_err := source_code.peek(src, 0)
	if sys.is_error(peek_err) {
		return nil, peek_err
	}
	switch (character) {
	case 'b':
		fallthrough
	case 'B':
		word, match, err := match_and_consume(src, grammar.BREAK)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .BREAK, word)
		}
	case 'c':
		fallthrough
	case 'C':
		word, match, err := match_and_consume(src, grammar.CONST)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .CONST, word)
		}
		word, match, err = match_and_consume(src, grammar.CONTINUE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .CONTINUE, word)
		}
		word, match, err = match_and_consume(src, grammar.CLEAR)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .CLEAR, word)
		}

	case 'e':
		fallthrough
	case 'E':
		word, match, err := match_and_consume(src, grammar.ELSE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .ELSE, word)
		}
		word, match, err = match_and_consume(src, grammar.ELSE_IF)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .ELSE_IF, word)
		}
		word, match, err = match_and_consume(src, grammar.ERROR)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .ERROR, word)
		}
		word, match, err = match_and_consume(src, grammar.EXISTS)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .EXISTS, word)
		}
	case 'f':
		fallthrough
	case 'F':
		word, match, err := match_and_consume(src, grammar.FOR)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .FOR, word)
		}
		word, match, err = match_and_consume(src, grammar.FALSE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .FALSE, word)
		}
		word, match, err = match_and_consume(src, grammar.FUNCTION)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .FUNCTION, word)
		}
	case 'i':
		fallthrough
	case 'I':
		word, match, err := match_and_consume(src, grammar.IF)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .IF, word)
		}
		word, match, err = match_and_consume(src, grammar.IN)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .IN, word)
		}
	case 'n':
		fallthrough
	case 'N':
		word, match, err := match_and_consume(src, grammar.NULL)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .NULL, word)
		}
	case 'm':
		fallthrough
	case 'M':
		match, err := is_next_word_match(src, grammar.MODULE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			_, adv_err := source_code.advance(src, 2)
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
			path, path_err := consume_string(src)
			if sys.is_error(path_err) {
				return nil, .PATH_CANT_BE_PARSED
			}
			_, adv_err = source_code.advance(src)
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
			imp_err := source_code.import_file(src, path)
			if sys.is_error(imp_err) {
				return nil, imp_err
			}
			return token.create(src, .TERMINATOR, "")
		}
	case 'k':
		fallthrough
	case 'K':
		word, match, err := match_and_consume(src, grammar.KEY)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .KEY, word)
		}

	case 'o':
		fallthrough
	case 'O':
		word, match, err := match_and_consume(src, grammar.OUT)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .OUT, word)
		}
	case 'l':
		fallthrough
	case 'L':
		word, match, err := match_and_consume(src, grammar.LENGTH)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .LENGTH, word)
		}
	case 'p':
		fallthrough
	case 'P':
		word, match, err := match_and_consume(src, grammar.PRINT_LINE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .PRINT_LINE, word)
		}
		word, match, err = match_and_consume(src, grammar.PRINT)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .PRINT, word)
		}
	case 's':
		fallthrough
	case 'S':
		word, match, err := match_and_consume(src, grammar.SLEEP)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .SLEEP, word)
		}
	case 'r':
		fallthrough
	case 'R':
		word, match, err := match_and_consume(src, grammar.RETURN)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .RETURN, word)
		}
		word, match, err = match_and_consume(src, grammar.FILE_REMOVE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .RM, word)
		}
		word, match, err = match_and_consume(src, grammar.REMOVE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .REMOVE, word)
		}
	case 't':
		fallthrough
	case 'T':
		word, match, err := match_and_consume(src, grammar.TRUE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .TRUE, word)
		}
		word, match, err = match_and_consume(src, grammar.TIME)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .TIME, word)
		}
	case 'v':
		fallthrough
	case 'V':
		word, match, err := match_and_consume(src, grammar.VAR)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .VAR, word)
		}
	case 'w':
		fallthrough
	case 'W':
		word, match, err := match_and_consume(src, grammar.WHILE)
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			return token.create(src, .WHILE, word)
		}
	case '&':
		second_char, second_char_err := source_code.peek(src, 1)
		if sys.is_error(second_char_err) {
			return nil, second_char_err
		}
		if second_char == '&' {
			_, adv_err := source_code.advance(src, 2)
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
			return token.create(src, .AND, "&&")
		}
	case '|':
		second_char, second_char_err := source_code.peek(src, 1)
		if sys.is_error(second_char_err) {
			return nil, second_char_err
		}
		if second_char == '|' {
			_, err := source_code.advance(src, 2)
			if sys.is_error(err) {
				return nil, err
			}
			return token.create(src, .OR, "||")
		}
	case '@':
		source_code.advance(src)
		file, file_err := consume_string(src)
		if sys.is_error(file_err) {
			return nil, file_err
		}
		return token.create(src, .AT, file)
	}
	return nil, .OK
}

run :: proc(src: ^types.source_code_t) -> (^types.token_list_t, types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	list, list_err := token_list.create()
	if sys.is_error(list_err) {
		return nil, list_err
	}
	for !src.is_at_end {
		tmp := (list.length > 0) ? list.list[list.length - 1] : nil
		character, character_err := source_code.advance(src)
		if character_err != .EOF_IN_SOURCE_CODE_REACHED {
			if sys.is_error(character_err) {
				return nil, character_err
			}
		}
		switch (character) {
		case '(':
			tok, tok_err := token.create(src, .LEFT_PAREN, "(")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case ')':
			tok, tok_err := token.create(src, .RIGHT_PAREN, ")")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '{':
			tok, tok_err := token.create(src, .LEFT_BRACE, "{")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '}':
			if tmp == nil {
				break
			}
			if tmp.type != .TERMINATOR {
				tok, tok_err := token.create(src, .TERMINATOR, ";")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
			tok, tok_err := token.create(src, .RIGHT_BRACE, "}")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '[':
			tok, tok_err := token.create(src, .LEFT_BRACKET, "[")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case ']':
			tok, tok_err := token.create(src, .RIGHT_BRACKET, "]")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case ',':
			tok, tok_err := token.create(src, .COMMA, ",")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case ':':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '^' {
				tok, tok_err := token.create(src, .COLON_HAT, ":^")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}

			} else {
				tok, tok_err := token.create(src, .COLON, ":")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '.':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if is_number(second_char) {
				number, number_err := consume_number(src)
				if sys.is_error(number_err) {
					return nil, number_err
				}
				tok, tok_err := token.create(src, .NUMBER, number)
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			} else if second_char == '.' {
				tok, tok_err := token.create(src, .DOT_DOT, "..")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .DOT, ".")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '-':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .MINUS_EQUAL, "-=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else if second_char == '>' {
				tok, tok_err := token.create(src, .RIGHT_ARROW, "->")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .MINUS, "-")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '+':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .PLUS_EQUAL, "+=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .PLUS, "+")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '%':
			tok, tok_err := token.create(src, .MODULUS, "%")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '/':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) && second_char_err != .PEEK_OUT_OF_BOUNDS {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .SLASH_EQUAL, "/=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .SLASH, "/")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '*':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .STAR_EQUAL, "*=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .STAR, "*")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '\'':
			fallthrough
		case '"':
			str, str_err := consume_string(src)
			if sys.is_error(str_err) {
				return nil, str_err
			}
			tok, tok_err := token.create(src, .STRING_WRAPPER, str)
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '!':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .BANG_EQUAL, "!=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .BANG, "!")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '=':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .EQUAL_EQUAL, "==")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .EQUAL, "=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '>':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .GREATER_EQUAL, ">=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .GREATER, ">")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		case '<':
			second_char, second_char_err := source_code.peek(src, 1)
			if sys.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, .LESS_EQUAL, "<=")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else if second_char == '-' {
				tok, tok_err := token.create(src, .LEFT_ARROW, "<-")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, .LESS, "<")
				if sys.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if sys.is_error(add_err) {
					return nil, add_err
				}
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
			number, number_err := consume_number(src)
			if sys.is_error(number_err) {
				return nil, number_err
			}
			tok, tok_err := token.create(src, .NUMBER, number)
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '\n':
			if tmp == nil {
				break
			}
			if tmp.type == .LEFT_PAREN || tmp.type == .TERMINATOR || tmp.type == .LEFT_BRACE {
				break
			}
			fallthrough
		case ';':
			tok, tok_err := token.create(src, .TERMINATOR, ";")
			if sys.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if sys.is_error(add_err) {
				return nil, add_err
			}
		case '\t':
		case ' ':
		case '#':
			err := consume_comment(src)
			if sys.is_error(err) {
				return nil, err
			}
		case:
			if src.is_at_end {
				break
			}
			if src.content[src.pointer] == 0 {
				break
			}
			res_word, err := consume_reserved_word(src)
			if sys.is_error(err) && err != .PEEK_OUT_OF_BOUNDS {
				return nil, err
			}
			if res_word == nil {
				word, word_err := consume_identifier(src)
				if sys.is_error(word_err) && word_err != .PEEK_OUT_OF_BOUNDS {
					return nil, word_err
				}
				if len(word.literal) > 0 {
					add_err := token_list.add(list, word)
					if sys.is_error(add_err) {
						return nil, add_err
					}
				}
			} else {
				add_err := token_list.add(list, res_word)
				if sys.is_error(add_err) {
					return nil, add_err
				}
			}
		}
	}
	term_char, term_char_err := token_list.peek(list, 0)
	if sys.is_error(term_char_err) {
		return nil, term_char_err
	}
	if term_char.type != .TERMINATOR {
		tok, tok_err := token.create(src, .TERMINATOR, ";")
		if sys.is_error(tok_err) {
			return nil, tok_err
		}
		add_err := token_list.add(list, tok)
		if sys.is_error(add_err) {
			return nil, add_err
		}
	}
	tok, tok_err := token.create(src, .END_OF_FILE, "EOF")
	if sys.is_error(tok_err) {
		return nil, tok_err
	}
	add_err := token_list.add(list, tok)
	if sys.is_error(add_err) {
		return nil, add_err
	}
	return list, .OK
}
