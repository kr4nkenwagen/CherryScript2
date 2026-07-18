package scan

import "../error"
import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:strings"
import "core:unicode"

consume_comment :: proc(src: ^types.source_code_t) -> types.exit_codes {
	if src == nil {
		return types.exit_codes.OBJECT_IS_NIL
	}
	char, peek_err := source_code.peek(src, 0)
	if char != '#' {
		return types.exit_codes.UNEXPECTED_CHARACTER
	}
	if error.is_error(peek_err) {
		return peek_err
	}
	for !src.is_at_end {
		c, adv_err := source_code.advance(src)
		if error.is_error(adv_err) {
			return adv_err
		}
		if c == '\n' || c == '#' {
			return types.exit_codes.OK
		}
	}
	return types.exit_codes.OK
}

consume_string :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil {
		return "", types.exit_codes.OBJECT_IS_NIL
	}
	start_char, peek_err := source_code.peek(src, 0)
	if error.is_error(peek_err) {
		return "", peek_err
	}
	if start_char != '\'' && start_char != '"' {
		return "", types.exit_codes.UNEXPECTED_CHARACTER
	}
	exit_char := start_char == '"' ? '"' : '\''
	size := int(1)
	for {
		char, err := source_code.peek(src, size)
		if error.is_error(err) {
			return "", err
		}
		if char == exit_char {
			break
		}
		size += 1
		if src.pointer + size >= src.length {
			return "", types.exit_codes.EOF_IN_STRING
		}
	}
	i := 0
	for i < size - 1 {
		_, err := source_code.advance(src)
		if error.is_error(err) {
			return "", err
		}
	}
	return src.content[src.pointer:src.pointer + size], types.exit_codes.OK
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
		return "", types.exit_codes.OBJECT_IS_NIL
	}
	start_position := src.pointer
	for !src.is_at_end {
		char, err := source_code.advance(src)
		if error.is_error(err) {
			return "", err
		}
		if is_end_of_word(char) {
			break
		}
	}
	total_length := int(src.pointer - start_position)
	if total_length <= 0 {
		return "", types.exit_codes.WORD_NOT_FOUND
	}
	word := string(src.content[start_position:start_position + total_length])
	return word, types.exit_codes.OK
}

consume_number :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil {
		return "", types.exit_codes.OBJECT_IS_NIL
	}
	is_float := false
	start_position := src.pointer
	for !src.is_at_end {
		character, peek_err := source_code.peek(src, 0)
		if error.is_error(peek_err) {
			return "", peek_err
		}
		second_char, err := source_code.peek(src, 1)
		if error.is_error(err) && err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
			return "", err
		}
		if character == '.' {
			if second_char == '.' {
				break
			}
			if is_float {
				return "", types.exit_codes.UNEXPECTED_CHARACTER
			}
			is_float = true
		}
		if is_number(second_char) {
			_, adv_err := source_code.advance(src)
			if error.is_error(adv_err) {
				return "", adv_err
			}
		} else {
			break
		}
	}
	total_length := int(src.pointer - start_position) + 1
	result := string(src.content[start_position:start_position + total_length])
	return result, types.exit_codes.OK
}

is_next_word_match :: proc(src: ^types.source_code_t, word: string) -> (bool, types.exit_codes) {
	if src == nil {
		return false, types.exit_codes.OBJECT_IS_NIL
	}
	if src.pointer + len(word) >= src.length {
		return false, types.exit_codes.OK
	}
	return strings.to_lower(src.content[src.pointer:src.pointer + len(word)]) == word,
		types.exit_codes.OK
}

consume_identifier :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	prev_char, peek_err := source_code.peek(src, -1)
	if error.is_error(peek_err) {
		return nil, peek_err
	}
	if unicode.is_alpha(prev_char) {
		return nil, types.exit_codes.UNEXPECTED_CHARACTER
	}
	word, err := consume_word(src)
	if error.is_error(err) {
		return nil, err
	}
	return token.create(src, types.token_type_t.IDENTIFIER, word)
}

consume_reserved_word :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	prev_char, prev_char_err := source_code.peek(src, -1)
	if error.is_error(prev_char_err) && prev_char_err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
		return nil, prev_char_err
	}
	if unicode.is_alpha(prev_char) {
		return nil, types.exit_codes.UNEXPECTED_CHARACTER
	}
	character, peek_err := source_code.peek(src, 0)
	if error.is_error(peek_err) {
		return nil, peek_err
	}
	switch (character) {
	case 'a':
		fallthrough
	case 'A':
		match, err := is_next_word_match(src, "and")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, err := consume_word(src)
			if error.is_error(err) {
				return nil, err
			}
			return token.create(src, types.token_type_t.AND, word)
		}
	case 'b':
		fallthrough
	case 'B':
		match, err := is_next_word_match(src, "break")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, err := consume_word(src)
			if error.is_error(err) {
				return nil, err
			}
			return token.create(src, types.token_type_t.BREAK, word)
		}
	case 'c':
		fallthrough
	case 'C':
		match, err := is_next_word_match(src, "class")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, match_err := consume_word(src)
			if error.is_error(match_err) {
				return nil, match_err
			}
			return token.create(src, types.token_type_t.CLASS, word)
		}
		match, err = is_next_word_match(src, "const")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, match_err := consume_word(src)
			if error.is_error(match_err) {
				return nil, match_err
			}
			return token.create(src, types.token_type_t.CONST, word)
		}
		match, err = is_next_word_match(src, "continue")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, match_err := consume_word(src)
			if error.is_error(match_err) {
				return nil, match_err
			}
			return token.create(src, types.token_type_t.CONTINUE, word)
		}
	case 'e':
		fallthrough
	case 'E':
		match, err := is_next_word_match(src, "else")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			first_char, first_char_err := source_code.peek(src, 6)
			if error.is_error(first_char_err) &&
			   first_char_err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
				return nil, first_char_err
			}
			second_char, second_char_err := source_code.peek(src, 7)
			if error.is_error(second_char_err) &&
			   second_char_err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
				return nil, second_char_err
			}
			if first_char == 'i' && second_char == 'f' {
				str1, str1_err := consume_word(src)
				if error.is_error(str1_err) {
					return nil, str1_err
				}
				str2, str2_err := consume_word(src)
				if error.is_error(str2_err) {
					return nil, str2_err
				}
				word := strings.concatenate({str1, string(" "), str2})
				return token.create(src, types.token_type_t.ELSE_IF, word)
			}
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.ELSE, word)
		}
	case 'f':
		fallthrough
	case 'F':
		match, err := is_next_word_match(src, "for")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.FOR, word)
		}
		match, err = is_next_word_match(src, "false")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.FALSE, word)
		}
		match, err = is_next_word_match(src, "fn")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.FUNCTION, word)
		}
	case 'i':
		fallthrough
	case 'I':
		match, err := is_next_word_match(src, "if")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.IF, word)
		}
	case 'n':
		fallthrough
	case 'N':
		match, err := is_next_word_match(src, "null")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.NIL, word)
		}
		match, err = is_next_word_match(src, "nil")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.NIL, word)
		}
	case 'm':
		fallthrough
	case 'M':
		match, err := is_next_word_match(src, "module")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			source_code.advance(src)
			source_code.advance(src)
			path, path_err := consume_string(src)
			if error.is_error(path_err) {
				return nil, types.exit_codes.PATH_CANT_BE_PARSED
			}
			_, adv_err := source_code.advance(src)
			if error.is_error(adv_err) {
				return nil, adv_err
			}
			imp_err := source_code.import_file(src, path)
			if error.is_error(imp_err) {
				return nil, imp_err
			}
			return token.create(src, types.token_type_t.TERMINATOR, "")
		}
	case 'o':
		fallthrough
	case 'O':
		match, err := is_next_word_match(src, "or")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.OR, word)
		}
		match, err = is_next_word_match(src, "or")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, err
			}
			return token.create(src, types.token_type_t.OUT, word)
		}
	case 'p':
		fallthrough
	case 'P':
		match, err := is_next_word_match(src, "println")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.PRINT_LINE, word)
		}
		match, err = is_next_word_match(src, "print")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.PRINT, word)
		}
	case 'r':
		fallthrough
	case 'R':
		match, err := is_next_word_match(src, "return")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.RETURN, word)
		}
		match, err = is_next_word_match(src, "return")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.REMOVE, word)
		}
	case 's':
		fallthrough
	case 'S':
		match, err := is_next_word_match(src, "super")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.SUPER, word)
		}
	case 't':
		fallthrough
	case 'T':
		match, err := is_next_word_match(src, "this")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.THIS, word)
		}
		match, err = is_next_word_match(src, "true")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.TRUE, word)
		}
	case 'v':
		fallthrough
	case 'V':
		match, err := is_next_word_match(src, "var")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.VAR, word)
		}
	case 'w':
		fallthrough
	case 'W':
		match, err := is_next_word_match(src, "while")
		if error.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if error.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, types.token_type_t.WHILE, word)
		}
	case '&':
		second_char, second_char_err := source_code.peek(src, 1)
		if error.is_error(second_char_err) {
			return nil, second_char_err
		}
		if second_char == '&' {
			_, adv_err := source_code.advance(src)
			if error.is_error(adv_err) {
				return nil, adv_err
			}
			_, adv_err = source_code.advance(src)
			if error.is_error(adv_err) {
				return nil, adv_err
			}
			return token.create(src, types.token_type_t.AND, "&&")
		}
	case '|':
		second_char, second_char_err := source_code.peek(src, 1)
		if error.is_error(second_char_err) {
			return nil, second_char_err
		}
		if second_char == '|' {
			_, err := source_code.advance(src)
			if error.is_error(err) {
				return nil, err
			}
			_, err = source_code.advance(src)
			if error.is_error(err) {
				return nil, err
			}
			return token.create(src, types.token_type_t.OR, "||")
		}
	}
	return nil, types.exit_codes.OK
}

run :: proc(src: ^types.source_code_t) -> (^types.token_list_t, types.exit_codes) {
	if src == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	list, list_err := token_list.create()
	if error.is_error(list_err) {
		return nil, list_err
	}
	for !src.is_at_end {
		tmp := (list.length > 0) ? list.list[list.length - 1] : nil
		character, character_err := source_code.advance(src)
		if error.is_error(character_err) &&
		   character_err != types.exit_codes.EOF_IN_SOURCE_CODE_REACHED {
			return nil, character_err
		}
		switch (character) {
		case '(':
			tok, tok_err := token.create(src, types.token_type_t.LEFT_PAREN, "(")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case ')':
			tok, tok_err := token.create(src, types.token_type_t.RIGHT_PAREN, ")")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '{':
			tok, tok_err := token.create(src, types.token_type_t.LEFT_BRACE, "{")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '}':
			if tmp == nil {
				break
			}
			if tmp.type != types.token_type_t.TERMINATOR {
				tok, tok_err := token.create(src, types.token_type_t.TERMINATOR, ";")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
			tok, tok_err := token.create(src, types.token_type_t.RIGHT_BRACE, "}")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '[':
			tok, tok_err := token.create(src, types.token_type_t.LEFT_BRACE, "[")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case ']':
			tok, tok_err := token.create(src, types.token_type_t.RIGHT_BRACE, "]")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case ',':
			tok, tok_err := token.create(src, types.token_type_t.COMMA, ",")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case ':':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '^' {
				tok, tok_err := token.create(src, types.token_type_t.COLON_HAT, ":^")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.COLON, ":")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '.':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if is_number(second_char) {
				number, number_err := consume_number(src)
				if error.is_error(number_err) {
					return nil, number_err
				}
				tok, tok_err := token.create(src, types.token_type_t.NUMBER, number)
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			} else if second_char == '.' {
				tok, tok_err := token.create(src, types.token_type_t.DOT_DOT, "..")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.DOT, ".")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '-':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.MINUS_EQUAL, "-=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.MINUS, "-")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '+':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.PLUS_EQUAL, "+=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.PLUS, "+")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '%':
			tok, tok_err := token.create(src, types.token_type_t.MODULUS, "%")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '/':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) &&
			   second_char_err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.SLASH_EQUAL, "/=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.SLASH, "/")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '*':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.STAR_EQUAL, "*=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.STAR, "*")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '\'':
			fallthrough
		case '"':
			str, str_err := consume_string(src)
			if error.is_error(str_err) {
				return nil, str_err
			}
			tok, tok_err := token.create(src, types.token_type_t.STRING_WRAPPER, str)
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '!':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.BANG_EQUAL, "!=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.BANG, "!")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '=':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.EQUAL_EQUAL, "==")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.EQUAL, "=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '>':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.GREATER_EQUAL, ">=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.GREATER, ">")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		case '<':
			second_char, second_char_err := source_code.peek(src, 1)
			if error.is_error(second_char_err) {
				return nil, second_char_err
			}
			if second_char == '=' {
				tok, tok_err := token.create(src, types.token_type_t.LESS_EQUAL, "<=")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
					return nil, add_err
				}
				_, adv_err := source_code.advance(src)
				if error.is_error(adv_err) {
					return nil, adv_err
				}
			} else {
				tok, tok_err := token.create(src, types.token_type_t.LESS, "<")
				if error.is_error(tok_err) {
					return nil, tok_err
				}
				add_err := token_list.add(list, tok)
				if error.is_error(add_err) {
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
			if error.is_error(number_err) {
				return nil, number_err
			}
			tok, tok_err := token.create(src, types.token_type_t.NUMBER, number)
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '\n':
			if tmp == nil {
				break
			}
			if tmp.type == types.token_type_t.LEFT_PAREN ||
			   tmp.type == types.token_type_t.TERMINATOR ||
			   tmp.type == types.token_type_t.LEFT_BRACE {
				break
			}
			fallthrough
		case ';':
			tok, tok_err := token.create(src, types.token_type_t.TERMINATOR, ";")
			if error.is_error(tok_err) {
				return nil, tok_err
			}
			add_err := token_list.add(list, tok)
			if error.is_error(add_err) {
				return nil, add_err
			}
		case '\t':
		case ' ':
		case '#':
			err := consume_comment(src)
			if error.is_error(err) {
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
			if error.is_error(err) && err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
				return nil, err
			}
			if res_word == nil {
				word, word_err := consume_identifier(src)
				if error.is_error(word_err) && word_err != types.exit_codes.PEEK_OUT_OF_BOUNDS {
					return nil, word_err
				}
				if len(word.literal) > 0 {
					add_err := token_list.add(list, word)
					if error.is_error(add_err) {
						return nil, add_err
					}
				}
			} else {
				add_err := token_list.add(list, res_word)
				if error.is_error(add_err) {
					return nil, add_err
				}
			}
		}
	}
	term_char, term_char_err := token_list.peek(list, 0)
	if error.is_error(term_char_err) {
		return nil, term_char_err
	}
	if term_char.type != types.token_type_t.TERMINATOR {
		tok, tok_err := token.create(src, types.token_type_t.TERMINATOR, ";")
		if error.is_error(tok_err) {
			return nil, tok_err
		}
		add_err := token_list.add(list, tok)
		if error.is_error(add_err) {
			return nil, add_err
		}
	}
	tok, tok_err := token.create(src, types.token_type_t.END_OF_FILE, "EOF")
	if error.is_error(tok_err) {
		return nil, tok_err
	}
	add_err := token_list.add(list, tok)
	if error.is_error(add_err) {
		return nil, add_err
	}
	return list, types.exit_codes.OK
}
