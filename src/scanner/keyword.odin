package scan

import "../grammar"
import "../types"

consume_keyword :: proc(tkn_list: ^types.token_list_t) -> (code: types.exit_codes) {
	for x := 0; x < len(tkn_list.list); x += 1 {
		for i := 0; i < len(grammar.keywords); i += 1 {
			if tkn_list.list[x].type == .STRING_WRAPPER do continue
			if tkn_list.list[x].literal == grammar.keywords[i].literal {
				if x > 0 {
					if tkn_list.list[x - 1].type == .DOT do break
				}
				tkn_list.list[x].type = grammar.keywords[i].type
			}
		}
	}
	return
}
