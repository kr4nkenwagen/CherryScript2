package token_list

import "../token"
import "../types"

create :: proc() -> (list: ^types.token_list_t, code: types.exit_codes) {
	list = new(types.token_list_t)
	if list == nil do return nil, .MEMORY_ALLOCATION_FAILED_IN_TOKEN_LIST_CREATE
	list.length = 0
	list.pointer = 0
	return
}

add :: proc(list: ^types.token_list_t, token: ^types.token_t) -> (code: types.exit_codes) {
	if list == nil do return .OBJECT_IS_NIL_IN_TOKEN_LIST_ADD
	append(&list.list, token)
	list.length += 1
	return
}

advance :: proc(list: ^types.token_list_t) -> (tkn: ^types.token_t, code: types.exit_codes) {
	if list == nil do return token.generate_unknown_token()
	list.pointer += 1
	if list.pointer >= list.length do return nil, .RAN_OUT_OF_TOKENS_IN_TOKEN_LIST_ADVANCE
	tkn = list.list[list.pointer]
	return
}

peek :: proc(
	list: ^types.token_list_t,
	distance: int,
) -> (
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	if list == nil || list.pointer + distance >= list.length do return token.generate_unknown_token()
	tkn = list.list[list.pointer + distance]
	return
}

remove :: proc(list: ^types.token_list_t) -> (code: types.exit_codes) {
	if list == nil do return
	delete(list.list)
	free(list)
	return
}
