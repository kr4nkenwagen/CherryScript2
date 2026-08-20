package token_list

import "../token"
import "../types"

create :: proc() -> (^types.token_list_t, types.exit_codes) {
	list := new(types.token_list_t)
	if list == nil do return nil, .MEMORY_ALLOCATION_FAILED_IN_TOKEN_LIST_CREATE
	list.length = 0
	list.pointer = 0
	return list, .OK
}

add :: proc(list: ^types.token_list_t, token: ^types.token_t) -> types.exit_codes {
	if list == nil do return .OBJECT_IS_NIL_IN_TOKEN_LIST_ADD
	append(&list.list, token)
	list.length += 1
	return .OK
}

advance :: proc(list: ^types.token_list_t) -> (^types.token_t, types.exit_codes) {
	if list == nil do return token.generate_unknown_token()
	list.pointer += 1
	if list.pointer >= list.length do return nil, .RAN_OUT_OF_TOKENS_IN_TOKEN_LIST_ADVANCE
	return list.list[list.pointer], .OK
}

peek :: proc(list: ^types.token_list_t, distance: int) -> (^types.token_t, types.exit_codes) {
	if list == nil || list.pointer + distance >= list.length do return token.generate_unknown_token()
	return list.list[list.pointer + distance], .OK
}

remove :: proc(list: ^types.token_list_t) -> types.exit_codes {
	if list == nil do return .OK
	delete(list.list)
	free(list)
	return .OK
}
