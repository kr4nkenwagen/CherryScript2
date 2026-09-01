package scan

import "../source_code"
import "../token"
import "../token_list"
import "../types"

run :: proc(src: ^types.source_code_t) -> (tkn_list: ^types.token_list_t, code: types.exit_codes) {
	if src == nil do return nil, .OBJECT_IS_NIL_IN_SCANNER
	tkn_list = token_list.create() or_return
	order_symbols_by_literal_length()
	for !src.is_at_end {
		c, adv_err := source_code.advance(src)
		if adv_err == .EOF_IN_SOURCE_CODE_REACHED_IN_SOURCE_CODE_ADVANCE {
			break
		}
		if (consume_module(tkn_list, src) or_return) do continue
		if (consume_comment(src) or_return) do continue
		if (consume_number(tkn_list, src) or_return) do continue
		if (consume_string(tkn_list, src) or_return) do continue
		if (consume_symbols(tkn_list, src) or_return) do continue
		if (consume_identifier(tkn_list, src) or_return) do continue
	}
	consume_keyword(tkn_list) or_return
	append_list_tail(tkn_list)
	remove_dupe_terminators(tkn_list) or_return
	return
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
