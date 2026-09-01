package scan

import "../grammar"
import "../source_code"
import "../token"
import "../token_list"
import "../types"

consume_module :: proc(
	tkn_list: ^types.token_list_t,
	src: ^types.source_code_t,
) -> (
	consumed: bool,
	code: types.exit_codes,
) {
	match := is_next_word_match(src, grammar.MODULE) or_return
	if match {
		word := consume_word(src) or_return
		source_code.advance(src, 2) or_return
		path := extract_string(src) or_return
		source_code.advance(src) or_return
		source_code.import_file(src, path) or_return
		tkn := token.create(src, .TERMINATOR, "") or_return
		token_list.add(tkn_list, tkn) or_return
		consumed = true
		return
	}
	return
}
