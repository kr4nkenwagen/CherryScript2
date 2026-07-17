package scan

import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:strings"
import "core:unicode"

consume_comment :: proc(src: ^types.source_code_t) -> types.exit_codes {
	if src == nil || source_code.peek(src, 0) != '#' {
		return types.exit_codes.OBJECT_IS_NIL
	}
	for !src.is_at_end {
		c := rune(source_code.advance(src))
		if c == '\n' || c == '#' {
			return types.exit_codes.OK
		}
	}
	return types.exit_codes.OK
}

consume_string :: proc(src: ^types.source_code_t) -> (string, types.exit_codes) {
	if src == nil || (source_code.peek(src, 0) != '\'' && source_code.peek(src, 0) != '"') {
		return "", types.exit_codes.OBJECT_IS_NIL
	}
	exit_char := rune(source_code.peek(src, 0)) == '"' ? '"' : '\''
	size := int(1)
	for source_code.peek(src, size) != exit_char {
		size += 1
		if src.pointer + size >= src.length {
			return "", types.exit_codes.EOF_IN_STRING
		}
	}
	i := 0
	for i < size - 1 {
		source_code.advance(src)
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
		if is_end_of_word(source_code.advance(src)) {
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
		character := rune(source_code.peek(src, 0))
		if character == '.' {
			if rune(source_code.peek(src, 1)) == '.' {
				break
			}
			if is_float {
				return "", types.exit_codes.UNEXPECTED_CHARACTER
			}
			is_float = true
		}
		if is_number(source_code.peek(src, 1)) {
			source_code.advance(src)
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
	if src == nil || unicode.is_alpha(source_code.peek(src, -1)) {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	word, err := consume_word(src)
	if err != types.exit_codes.OK {
		return nil, err
	}
	return token.create(src, types.token_type_t.IDENTIFIER, word), types.exit_codes.OK
}

consume_reserved_word :: proc(src: ^types.source_code_t) -> (^types.token_t, types.exit_codes) {
	if src == nil || unicode.is_alpha(source_code.peek(src, -1)) {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	character := rune(source_code.peek(src, 0))
	switch (character) {
	case 'a':
		fallthrough
	case 'A':
		match, err := is_next_word_match(src, "and")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.AND, word), types.exit_codes.OK
		}
	case 'b':
		fallthrough
	case 'B':
		match, err := is_next_word_match(src, "break")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.BREAK, word), types.exit_codes.OK
		}
	case 'c':
		fallthrough
	case 'C':
		match, err := is_next_word_match(src, "class")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.CLASS, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "const")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.CONST, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "continue")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.CONTINUE, word), types.exit_codes.OK
		}
	case 'e':
		fallthrough
	case 'E':
		match, err := is_next_word_match(src, "else")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			if rune(source_code.peek(src, 6)) == 'i' && rune(source_code.peek(src, 7)) == 'f' {
				str1, _ := consume_word(src)
				str2, _ := consume_word(src)
				word := strings.concatenate({str1, string(" "), str2})
				return token.create(src, types.token_type_t.ELSE_IF, word), types.exit_codes.OK
			}
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.ELSE, word), types.exit_codes.OK
		}
	case 'f':
		fallthrough
	case 'F':
		match, err := is_next_word_match(src, "for")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.FOR, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "false")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.FALSE, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "fn")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.FUNCTION, word), types.exit_codes.OK
		}
	case 'i':
		fallthrough
	case 'I':
		match, err := is_next_word_match(src, "if")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.IF, word), types.exit_codes.OK
		}
	case 'n':
		fallthrough
	case 'N':
		match, err := is_next_word_match(src, "null")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.NIL, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "nil")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.NIL, word), types.exit_codes.OK
		}
	case 'm':
		fallthrough
	case 'M':
		match, err := is_next_word_match(src, "module")
		if err != types.exit_codes.OK || !match {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			source_code.advance(src)
			source_code.advance(src)
			path, path_err := consume_string(src)
			if path_err != types.exit_codes.OK {
				return nil, types.exit_codes.PATH_CANT_BE_PARSED
			}
			source_code.advance(src)
			source_code.import_file(src, path)
			return token.create(src, types.token_type_t.TERMINATOR, ""), types.exit_codes.OK
		}
	case 'o':
		fallthrough
	case 'O':
		match, err := is_next_word_match(src, "or")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.OR, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "or")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.OUT, word), types.exit_codes.OK
		}
	case 'p':
		fallthrough
	case 'P':
		match, err := is_next_word_match(src, "println")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.PRINT_LINE, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "print")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.PRINT, word), types.exit_codes.OK
		}
	case 'r':
		fallthrough
	case 'R':
		match, err := is_next_word_match(src, "return")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.RETURN, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "return")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.REMOVE, word), types.exit_codes.OK
		}
	case 's':
		fallthrough
	case 'S':
		match, err := is_next_word_match(src, "super")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.SUPER, word), types.exit_codes.OK
		}
	case 't':
		fallthrough
	case 'T':
		match, err := is_next_word_match(src, "this")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.THIS, word), types.exit_codes.OK
		}
		match, err = is_next_word_match(src, "true")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.TRUE, word), types.exit_codes.OK
		}
	case 'v':
		fallthrough
	case 'V':
		match, err := is_next_word_match(src, "var")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.VAR, word), types.exit_codes.OK
		}
	case 'w':
		fallthrough
	case 'W':
		match, err := is_next_word_match(src, "while")
		if err != types.exit_codes.OK {
			return nil, err
		}
		if match {
			word, _ := consume_word(src)
			return token.create(src, types.token_type_t.WHILE, word), types.exit_codes.OK
		}
	case '&':
		if source_code.peek(src, 1) == '&' {
			source_code.advance(src)
			source_code.advance(src)
			return token.create(src, types.token_type_t.AND, "&&"), types.exit_codes.OK
		}
	case '|':
		if source_code.peek(src, 1) == '|' {
			source_code.advance(src)
			source_code.advance(src)
			return token.create(src, types.token_type_t.OR, "||"), types.exit_codes.OK
		}
	}
	return nil, types.exit_codes.OK
}


run :: proc(src: ^types.source_code_t) -> (^types.token_list_t, types.exit_codes) {
	if src == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
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
			if res_word == nil {
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
	return list, types.exit_codes.OK
}
