package token

import "../types"

create :: proc(
	src: ^types.source_code_t,
	type: types.token_type_t,
	literal: string,
) -> (
	^types.token_t,
	types.exit_codes,
) {
	if type == nil do return nil, types.exit_codes.OBJECT_IS_NIL
	token := new(types.token_t)
	if token == nil do return nil, types.exit_codes.MEMORY_ALLOCATION_FAILED
	token.literal = literal
	if src != nil {
		token.column = src.column
		token.line = src.line
	}
	token.type = type
	return token, types.exit_codes.OK
}

generate_unknown_token :: proc() -> (^types.token_t, types.exit_codes) {
	token := new(types.token_t)
	if token == nil do return nil, types.exit_codes.MEMORY_ALLOCATION_FAILED
	token.type = types.token_type_t.UNKNOWN_TOKEN
	return token, types.exit_codes.OK
}
