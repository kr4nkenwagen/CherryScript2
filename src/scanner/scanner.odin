package scan

import "../source_code"
import "../sys"
import "../token"
import "../token_list"
import "../types"

run :: proc(src: ^types.source_code_t) -> (tkn_list: ^types.token_list_t, code: types.exit_codes) {
	if src == nil do return nil, .OBJECT_IS_NIL_IN_SCANNER
	list := token_list.create() or_return
	for !src.is_at_end {
		tmp := (list.length > 0) ? list.list[list.length - 1] : nil
		character, character_err := source_code.advance(src)
		if character_err != .EOF_IN_SOURCE_CODE_REACHED_IN_SOURCE_CODE_ADVANCE {
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
			res_word, err := consume_keyword(src)
			if sys.is_error(err) && err != .OUT_OF_BOUNDS_IN_SOURCE_CODE_PEEK do return nil, err

			if res_word == nil {
				word, word_err := consume_identifier(src)
				if sys.is_error(word_err) && word_err != .OUT_OF_BOUNDS_IN_SOURCE_CODE_PEEK do return nil, word_err
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
