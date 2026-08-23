package token

import "../types"

create :: proc(
	src: ^types.source_code_t,
	type: types.token_type_t,
	literal: string,
) -> (
	token: ^types.token_t,
	code: types.exit_codes,
) {
	if type == nil do return nil, .OBJECT_IS_NIL_IN_TOKEN_CREATE
	token = new(types.token_t)
	if token == nil do return nil, .MEMORY_ALLOCATION_FAILED_IN_TOKEN_CREATE
	token.literal = literal
	if src != nil {
		token.column = src.column - len(token.literal)
		token.line = src.line
	}
	token.type = type
	return
}

generate_unknown_token :: proc() -> (token: ^types.token_t, code: types.exit_codes) {
	token = new(types.token_t)
	if token == nil do return nil, .MEMORY_ALLOCATION_FAILED_IN_TOKEN_GENERATE_UNKNOWN_TOKEN
	token.type = .UNKNOWN_TOKEN
	return
}
