package scan

import "../source_code"
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
