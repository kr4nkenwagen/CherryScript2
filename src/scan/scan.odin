package scan

import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:strings"
import "core:unicode"

consume_comment :: proc(src: ^types.source_code_t) -> bool {
	if src == nil || source_code.peek(src, 0) != '#' {
		return false
	}
	for !src.is_at_end {
		c := rune(source_code.advance(src))
		if c == '\n' || c == '#' {
			return true
		}
	}
	return true
}

consume_string :: proc(src: ^types.source_code_t) -> (string, bool) {
	if src == nil || (source_code.peek(src, 0) != '\'' && source_code.peek(src, 0) != '"') {
		return "", true
	}
	exit_char := rune(source_code.peek(src, 0)) == '"' ? '"' : '\''
	size := int(1)
	for source_code.peek(src, size) != exit_char {
		size += 1
		if src.pointer + size >= src.length {
			//ERROR HERE WE NEED TO ERR 'err_eof_in_string'
			return "", true
		}
	}
	i := 0
	for i < size - 1 {
		source_code.advance(src)
	}
	return src.content[src.pointer:src.pointer + size], false
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

consume_word :: proc(src: ^types.source_code_t) -> (string, bool) {
	if src == nil {
		return "", true
	}
	start_position := src.pointer
	for !src.is_at_end {
		if is_end_of_word(source_code.advance(src)) {
			break
		}
	}
	total_length := int(src.pointer - start_position)
	if total_length <= 0 {
		return "", true
	}
	return string(src.content[start_position:start_position + total_length]), false
}

consume_number :: proc(src: ^types.source_code_t) -> (string, bool) {
	if src == nil {
		return "", true
	}
	is_float := bool(false)
	start_position := src.pointer
	for !src.is_at_end {
		character := rune(source_code.peek(src, 0))
		if character == '.' {
			if rune(source_code.peek(src, 1)) == '.' {
				break
			}
			if is_float {
				//ERROR 'err_unexpected_character'
				return "", true
			}
			is_float = true
		}
		if is_number(source_code.peek(src, 1)) {
			source_code.advance(src)
		} else {
			break
		}
	}
	total_length := int(src.pointer - start_position)
	result := string(src.content[start_position:start_position + total_length])
	return result, false
}

is_next_word_match :: proc(src: ^types.source_code_t, word: string) -> (bool, bool) {
	if src == nil {
		return false, true
	}
	if src.pointer + len(word) >= src.length {
		return false, false
	}
	return strings.to_lower(src.content[src.pointer:src.pointer + len(word)]) == word, false
}

consume_identifier :: proc(src: ^types.source_code_t) -> (^types.token_t, bool) {
	if src == nil || unicode.is_alpha(source_code.peek(src, -1)) {
		return nil, true
	}
	word, err := consume_word(src)
	if err {
		return nil, false
	}
	return token.create(src, types.token_type_t.IDENTIFIER, word), false
}

match_specific_reserved_word :: proc(
	src: ^types.source_code_t,
	literal: string,
	token_type: types.token_type_t,
) -> (
	^types.token_t,
	bool,
) {
	return nil, false
}

consume_reserved_word :: proc(src: ^types.source_code_t) -> (^types.token_t, bool) {
	if src == nil || unicode.is_alpha(source_code.peek(src, -1)) {
		return nil, true
	}
	character := rune(source_code.peek(src, 0))
	switch (character) {
	case 'a':
		fallthrough
	case 'A':
		match, err := is_next_word_match(src, "and")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.AND, word), false
		}
	case 'b':
		fallthrough
	case 'B':
		match, err := is_next_word_match(src, "break")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.BREAK, word), false
		}
	case 'c':
		fallthrough
	case 'C':
		match, err := is_next_word_match(src, "class")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.CLASS, word), false
		}
		match, err = is_next_word_match(src, "const")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.CONST, word), false
		}
		match, err = is_next_word_match(src, "continue")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.CONTINUE, word), false
		}
	case 'e':
		fallthrough
	case 'E':
		match, err := is_next_word_match(src, "else")
		if err {
			return nil, true
		}
		if match {
			if rune(source_code.peek(src, 6)) == 'i' && rune(source_code.peek(src, 7)) == 'f' {
				str1, _ := consume_word(src)
				str2, _ := consume_word(src)
				word := strings.concatenate({str1, string(" "), str2})
				return token.create(src, types.token_type_t.ELSE_IF, word), false
			}
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.ELSE, word), false
		}
	case 'f':
		fallthrough
	case 'F':
		match, err := is_next_word_match(src, "for")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.FOR, word), false
		}
		match, err = is_next_word_match(src, "false")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.FALSE, word), false
		}
		match, err = is_next_word_match(src, "fn")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.FUNCTION, word), false
		}
	case 'i':
		fallthrough
	case 'I':
		match, err := is_next_word_match(src, "if")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.IF, word), false
		}
	case 'n':
		fallthrough
	case 'N':
		match, err := is_next_word_match(src, "null")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.NIL, word), false
		}
		match, err = is_next_word_match(src, "nil")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.NIL, word), false
		}

	case 'm':
		fallthrough
	case 'M':
		match, err := is_next_word_match(src, "module")
		if err || !match {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			source_code.advance(src)
			source_code.advance(src)
			path, path_err := consume_string(src)
			if path_err {
				//ERROR OUT IF WE END UP HERE
			}
			source_code.advance(src)
			source_code.import_file(src, path)
			return token.create(src, types.token_type_t.TERMINATOR, ""), false
		}
	case 'o':
		fallthrough
	case 'O':
		match, err := is_next_word_match(src, "or")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.OR, word), false
		}
		match, err = is_next_word_match(src, "or")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.OUT, word), false
		}
	case 'p':
		fallthrough
	case 'P':
		match, err := is_next_word_match(src, "println")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.PRINT_LINE, word), false
		}
		match, err = is_next_word_match(src, "print")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.PRINT, word), false
		}
	case 'r':
		fallthrough
	case 'R':
		match, err := is_next_word_match(src, "return")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.RETURN, word), false
		}
		match, err = is_next_word_match(src, "return")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.REMOVE, word), false
		}
	case 's':
		fallthrough
	case 'S':
		match, err := is_next_word_match(src, "super")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.SUPER, word), false
		}
	case 't':
		fallthrough
	case 'T':
		match, err := is_next_word_match(src, "this")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.THIS, word), false
		}
		match, err = is_next_word_match(src, "true")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.TRUE, word), false
		}
	case 'v':
		fallthrough
	case 'V':
		match, err := is_next_word_match(src, "var")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.VAR, word), false
		}
	case 'w':
		fallthrough
	case 'W':
		match, err := is_next_word_match(src, "while")
		if err {
			return nil, true
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.WHILE, word), false
		}
	case '&':
		if source_code.peek(src, 1) == '&' {
			source_code.advance(src)
			source_code.advance(src)
			return token.create(src, types.token_type_t.AND, "&&"), false
		}
	case '|':
		if source_code.peek(src, 1) == '|' {
			source_code.advance(src)
			source_code.advance(src)
			return token.create(src, types.token_type_t.OR, "||"), false
		}
	}
	return nil, true
}

run :: proc(src: ^types.source_code_t) -> (^types.token_list_t, bool) {
	if src == nil {
		//ERROR here
		return nil, true
	}
	list := token_list.create()
	for !src.is_at_end {
		tmp := (list.length > 0) ? list.list[list.length - 1] : nil
		character := source_code.advance(src)
		switch (character) {
		case '(':
			token_list.add(list, token.create(src, types.token_type_t.LEFT_PAREN, "("))
		case ')':
			token_list.add(list, token.create(src, types.token_type_t.RIGHT_PAREN, ")"))
		case '{':
			token_list.add(list, token.create(src, types.token_type_t.LEFT_BRACE, "{"))
		case '}':
			if tmp == nil {
				break
			}
			if tmp.type != types.token_type_t.TERMINATOR {
				token_list.add(list, token.create(src, types.token_type_t.TERMINATOR, ";"))
			}
			token_list.add(list, token.create(src, types.token_type_t.RIGHT_BRACE, "}"))
		case '[':
			token_list.add(list, token.create(src, types.token_type_t.LEFT_BRACE, "["))
		case ']':
			token_list.add(list, token.create(src, types.token_type_t.RIGHT_BRACE, "]"))
		case ',':
			token_list.add(list, token.create(src, types.token_type_t.COMMA, ","))
		case ':':
			if source_code.peek(src, 1) == '^' {
				token_list.add(list, token.create(src, types.token_type_t.COLON_HAT, ":^"))
			} else {
				token_list.add(list, token.create(src, types.token_type_t.COLON, ":"))
			}
		case '.':
			if is_number(source_code.peek(src, 1)) {
				number, _ := consume_number(src)
				token_list.add(list, token.create(src, types.token_type_t.NUMBER, number))
			} else if source_code.peek(src, 1) == '.' {
				token_list.add(list, token.create(src, types.token_type_t.DOT_DOT, ".."))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.DOT, "."))
			}
		case '-':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.MINUS_EQUAL, "-="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.MINUS, "-"))
			}
		case '+':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.PLUS_EQUAL, "+="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.PLUS, "+"))
			}
		case '%':
			token_list.add(list, token.create(src, types.token_type_t.MODULUS, "%"))
		case '/':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.SLASH_EQUAL, "/="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.SLASH, "/"))
			}
		case '*':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.STAR_EQUAL, "*="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.STAR, "*"))
			}
		case '\'':
			fallthrough
		case '"':
			str, _ := consume_string(src)
			token_list.add(list, token.create(src, types.token_type_t.STRING_WRAPPER, str))
		case '!':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.BANG_EQUAL, "!="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.BANG, "!"))
			}
		case '=':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.EQUAL_EQUAL, "=="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.EQUAL, "="))
			}
		case '>':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.GREATER_EQUAL, ">="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.GREATER, ">"))
			}
		case '<':
			if source_code.peek(src, 1) == '=' {
				token_list.add(list, token.create(src, types.token_type_t.LESS_EQUAL, "<="))
				source_code.advance(src)
			} else {
				token_list.add(list, token.create(src, types.token_type_t.LESS, "<"))
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
			number, _ := consume_number(src)
			token_list.add(list, token.create(src, types.token_type_t.NUMBER, number))
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
			token_list.add(list, token.create(src, types.token_type_t.TERMINATOR, ";"))
		case '\t':
		case ' ':
		case '#':
			_ = consume_comment(src)
		case:
			if src.is_at_end {
				break
			}
			if src.content[src.pointer] == 0 {
				break
			}
			res_word, err := consume_reserved_word(src)
			if err {
				word, err := consume_identifier(src)
				if len(word.literal) > 0 {
					token_list.add(list, word)
				}
			} else {
				token_list.add(list, res_word)
			}
		}
	}
	if token_list.peek(list, 0).type != types.token_type_t.TERMINATOR {
		token_list.add(list, token.create(src, types.token_type_t.TERMINATOR, ";"))
	}
	token_list.add(list, token.create(src, types.token_type_t.END_OF_FILE, "EOF"))
	return list, false
}
