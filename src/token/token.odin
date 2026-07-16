package token

import "../types"


create :: proc(
	src: ^types.source_code_t,
	type: types.token_type_t,
	literal: string,
) -> ^types.token_t {
	if type == nil {
		return nil
	}
	token := new(types.token_t)
	token.literal = literal
	token.column = src.column
	token.line = src.line
	token.type = type
	return token
}

generate_unknown_token :: proc() -> ^types.token_t {
	token := new(types.token_t)
	token.type = types.token_type_t.UNKNOWN_TOKEN
	return token
}
