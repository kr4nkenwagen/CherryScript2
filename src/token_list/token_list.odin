package token_list
import "../token"
import "../types"


create :: proc() -> (^types.token_list_t, types.exit_codes) {
	list := new(types.token_list_t)
	if list == nil {
		return nil, types.exit_codes.MEMORY_ALLOCATION_FAILED
	}
	list.length = 0
	list.pointer = 0
	return list, types.exit_codes.OK
}

add :: proc(list: ^types.token_list_t, token: ^types.token_t) -> types.exit_codes {
	if list == nil {
		return types.exit_codes.OBJECT_IS_NIL
	}
	append(&list.list, token)
	list.length += 1
	return types.exit_codes.OK
}

advance :: proc(list: ^types.token_list_t) -> (^types.token_t, types.exit_codes) {
	if list == nil {
		return token.generate_unknown_token()
	}
	list.pointer += 1
	return list.list[list.pointer], types.exit_codes.OK
}

peek :: proc(list: ^types.token_list_t, distance: int) -> (^types.token_t, types.exit_codes) {
	if list == nil || list.pointer + distance >= list.length {
		return token.generate_unknown_token()
	}
	return list.list[list.pointer + distance], types.exit_codes.OK
}

remove :: proc(list: ^types.token_list_t) -> types.exit_codes {
	delete(list.list)
	free(list)
	return types.exit_codes.OK
}
