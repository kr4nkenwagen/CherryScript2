package scan

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
	if char != '#' {
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
		if c == '\n' || c == '#' {
			return .OK
		}
	}
	return types.exit_codes.OK
}

consume_string :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil {
		return "", .OBJECT_IS_NIL
	}
	start_char, peek_err := source_code.peek(src, 0)
	if sys.is_error(peek_err) {
		return "", peek_err
	}
	if start_char != '\'' && start_char != '"' {
		return "", .UNEXPECTED_CHARACTER
	}
	exit_char := start_char == '"' ? '"' : '\''
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
	return word, types.exit_codes.OK
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
		if is_number(second_char) {
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
	return result, types.exit_codes.OK
}

is_next_word_match :: proc(src: ^types.source_code_t, word: string) -> (bool, types.exit_codes) {
	if src == nil {
		return false, .OBJECT_IS_NIL
	}
	if src.pointer + len(word) >= src.length {
		return false, types.exit_codes.OK
	}
	return strings.to_lower(src.content[src.pointer:src.pointer + len(word)]) == word,
		types.exit_codes.OK
}

consume_identifier :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	prev_char, peek_err := source_code.peek(src, -1)
	if sys.is_error(peek_err) {
		return nil, peek_err
	}
	if unicode.is_alpha(prev_char) {
		return nil, .UNEXPECTED_CHARACTER
	}
	word, err := consume_word(src)
	if sys.is_error(err) {
		return nil, err
	}
	return token.create(src, .IDENTIFIER, word)
}

consume_reserved_word :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	prev_char, prev_char_err := source_code.peek(src, -1)
	if sys.is_error(prev_char_err) && prev_char_err != .PEEK_OUT_OF_BOUNDS {
		return nil, prev_char_err
	}
	if unicode.is_alpha(prev_char) {
		return nil, .UNEXPECTED_CHARACTER
	}
	character, peek_err := source_code.peek(src, 0)
	if sys.is_error(peek_err) {
		return nil, peek_err
	}
	switch (character) {
	case 'a':
		fallthrough
	case 'A':
		match, err := is_next_word_match(src, "and")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, err := consume_word(src)
			if sys.is_error(err) {
				return nil, err
			}
			return token.create(src, .AND, word)
		}
	case 'b':
		fallthrough
	case 'B':
		match, err := is_next_word_match(src, "break")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, err := consume_word(src)
			if sys.is_error(err) {
				return nil, err
			}
			return token.create(src, .BREAK, word)
		}
	case 'c':
		fallthrough
	case 'C':
		match, err := is_next_word_match(src, "class")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, match_err := consume_word(src)
			if sys.is_error(match_err) {
				return nil, match_err
			}
			return token.create(src, .CLASS, word)
		}
		match, err = is_next_word_match(src, "const")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, match_err := consume_word(src)
			if sys.is_error(match_err) {
				return nil, match_err
			}
			return token.create(src, .CONST, word)
		}
		match, err = is_next_word_match(src, "continue")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, match_err := consume_word(src)
			if sys.is_error(match_err) {
				return nil, match_err
			}
			return token.create(src, .CONTINUE, word)
		}
	case 'e':
		fallthrough
	case 'E':
		match, err := is_next_word_match(src, "else")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			first_char, first_char_err := source_code.peek(src, 5)
			if sys.is_error(first_char_err) && first_char_err != .PEEK_OUT_OF_BOUNDS {
				return nil, first_char_err
			}
			second_char, second_char_err := source_code.peek(src, 6)
			if sys.is_error(second_char_err) && second_char_err != .PEEK_OUT_OF_BOUNDS {
				return nil, second_char_err
			}
			if first_char == 'i' && second_char == 'f' {
				str1, str1_err := consume_word(src)
				if sys.is_error(str1_err) {
					return nil, str1_err
				}
				_, adv_err := source_code.advance(src)
				if sys.is_error(adv_err) {
					return nil, adv_err
				}
				str2, str2_err := consume_word(src)
				if sys.is_error(str2_err) {
					return nil, str2_err
				}
				word := strings.concatenate({str1, string(" "), str2})
				return token.create(src, .ELSE_IF, word)
			}
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .ELSE, word)
		}
		match, err = is_next_word_match(src, "err")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .ERROR, word)
		}
	case 'f':
		fallthrough
	case 'F':
		match, err := is_next_word_match(src, "for")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .FOR, word)
		}
		match, err = is_next_word_match(src, "false")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .FALSE, word)
		}
		match, err = is_next_word_match(src, "fn")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .FUNCTION, word)
		}
	case 'i':
		fallthrough
	case 'I':
		match, err := is_next_word_match(src, "if")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .IF, word)
		}
		match, err = is_next_word_match(src, "in")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .IN, word)
		}
	case 'n':
		fallthrough
	case 'N':
		match, err := is_next_word_match(src, "null")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .NIL, word)
		}
		match, err = is_next_word_match(src, "nil")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .NIL, word)
		}
	case 'm':
		fallthrough
	case 'M':
		match, err := is_next_word_match(src, "module")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			source_code.advance(src)
			source_code.advance(src)
			path, path_err := consume_string(src)
			if sys.is_error(path_err) {
				return nil, types.exit_codes.PATH_CANT_BE_PARSED
			}
			_, adv_err := source_code.advance(src)
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
			imp_err := source_code.import_file(src, path)
			if sys.is_error(imp_err) {
				return nil, imp_err
			}
			return token.create(src, .TERMINATOR, "")
		}
	case 'o':
		fallthrough
	case 'O':
		match, err := is_next_word_match(src, "or")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .OR, word)
		}
		match, err = is_next_word_match(src, "out")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, err
			}
			return token.create(src, types.token_type_t.OUT, word)
		}
	case 'l':
		fallthrough
	case 'L':
		match, err := is_next_word_match(src, "len")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .LENGTH, word)
		}

	case 'p':
		fallthrough
	case 'P':
		match, err := is_next_word_match(src, "println")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .PRINT_LINE, word)
		}
		match, err = is_next_word_match(src, "print")
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
	case 'r':
		fallthrough
	case 'R':
		match, err := is_next_word_match(src, "return")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .RETURN, word)
		}
		match, err = is_next_word_match(src, "remove")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .REMOVE, word)
		}
	case 's':
		fallthrough
	case 'S':
		match, err := is_next_word_match(src, "super")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .SUPER, word)
		}
	case 't':
		fallthrough
	case 'T':
		match, err := is_next_word_match(src, "this")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .THIS, word)
		}
		match, err = is_next_word_match(src, "true")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .TRUE, word)
		}
	case 'v':
		fallthrough
	case 'V':
		match, err := is_next_word_match(src, "var")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .VAR, word)
		}
	case 'w':
		fallthrough
	case 'W':
		match, err := is_next_word_match(src, "while")
		if sys.is_error(err) {
			return nil, err
		}
		if match {
			word, word_err := consume_word(src)
			if sys.is_error(word_err) {
				return nil, word_err
			}
			return token.create(src, .WHILE, word)
		}
	case '&':
		second_char, second_char_err := source_code.peek(src, 1)
		if sys.is_error(second_char_err) {
			return nil, second_char_err
		}
		if second_char == '&' {
			_, adv_err := source_code.advance(src)
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
			_, adv_err = source_code.advance(src)
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
			_, err := source_code.advance(src)
			if sys.is_error(err) {
				return nil, err
			}
			_, err = source_code.advance(src)
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
		if sys.is_error(character_err) && character_err != .EOF_IN_SOURCE_CODE_REACHED {
			return nil, character_err
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
			if tmp.type != types.token_type_t.TERMINATOR {
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
