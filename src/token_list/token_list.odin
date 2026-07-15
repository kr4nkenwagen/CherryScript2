package token_list
import "../token"
import "../types"


create :: proc() -> ^types.token_list_t {
	list := new(types.token_list_t)
	list.length = 0
	list.pointer = 0
	return list
}

add :: proc(list: ^types.token_list_t, token: ^types.token_t) {
	if list == nil {
		return
	}
	append(&list.list, token)
	list.length += 1
}

advance :: proc(list: ^types.token_list_t) -> ^types.token_t {
	if list == nil {
		return token.generate_unknown_token()
	}
	list.pointer += 1
	return list.list[list.pointer]
}

peek :: proc(list: ^types.token_list_t, distance: int) -> ^types.token_t {
	if list == nil || list.pointer + distance >= list.length {
		return token.generate_unknown_token()
	}
	return list.list[list.pointer + distance]
}

remove :: proc(list: ^types.token_list_t) {
	delete(list.list)
	free(list)
}
