package scan

import "../grammar"
import "../source_code"
import "../token"
import "../token_list"
import "../types"
import "core:strings"

consume_symbols :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	if src == nil {
		return false, .OBJECT_IS_NIL_IN_SCANNER_SYMBOL
	}
	c := source_code.peek(src) or_return
	for i := 0; i < len(grammar.symbols); i += 1 {
		lit := grammar.symbols[i].literal
		lit_len := len(lit)
		if lit_len + src.pointer > len(src.content) do continue
		builder: strings.Builder
		strings.builder_init(&builder)
		defer strings.builder_destroy(&builder)
		matched := true
		for offset := 0; offset < lit_len; offset += 1 {
			ch := source_code.peek(src, offset) or_return
			strings.write_rune(&builder, ch)
		}
		peeked_str := strings.to_string(builder)
		if peeked_str == lit {
			source_code.advance(src, lit_len - 1) or_return
			if grammar.symbols[i].type == .RIGHT_BRACE do handle_right_brace(tkn_list, src)
			if grammar.symbols[i].literal == "\n" do return handle_right_newline(tkn_list, src)
			tkn := token.create(src, grammar.symbols[i].type, grammar.symbols[i].literal) or_return
			token_list.add(tkn_list, tkn) or_return
			consumed = true
			return

		}
	}
	return
}

handle_right_newline :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	is_in_paren := false
	for x := src.pointer; x >= 0; x -= 1 {
		if src.content[x] == '(' || src.content[x] == '[' {
			is_in_paren = true
			break
		} else if src.content[x] == ')' || src.content[x] == ']' {
			break
		}
	}
	if is_in_paren do return true, .OK
	if tkn_list.length > 0 {
		last_token := tkn_list.list[tkn_list.length - 1]
		if last_token.type != .TERMINATOR &&
		   last_token.type != .LEFT_PAREN &&
		   last_token.type != .LEFT_BRACE {
			tok := token.create(src, .TERMINATOR, ";") or_return
			token_list.add(tkn_list, tok) or_return
		}
	}
	consumed = true
	return
}

handle_right_subtract :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	last_token := (tkn_list.length > 0) ? tkn_list.list[tkn_list.length - 1] : nil
	if last_token.type != .TERMINATOR {
		tok := token.create(src, .TERMINATOR, ";") or_return
		token_list.add(tkn_list, tok) or_return
	}
	return
}

handle_right_brace :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	code: types.exit_codes,
) {
	last_token := (tkn_list.length > 0) ? tkn_list.list[tkn_list.length - 1] : nil
	if last_token.type != .TERMINATOR {
		tok := token.create(src, .TERMINATOR, ";") or_return
		token_list.add(tkn_list, tok) or_return
	}
	return
}
