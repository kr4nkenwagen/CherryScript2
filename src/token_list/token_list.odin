package token_list
import "../token"

token_list_t :: struct {
	list:    [dynamic]^token.token_t,
	length:  int,
	pointer: int,
}

token_list_new :: proc() -> ^token_list_t {
	list := new(token_list_t)
	list.length = 0
	list.pointer = 0
	return list
}

add :: proc(list: ^token_list_t, token: ^token.token_t) {
	if list == nil {
		return
	}
	list.length += 1
	list.list[list.length] = token
}

advance :: proc(list: ^token_list_t) -> ^token.token_t {
	if list == nil {
		return token.generate_unknown_token()
	}
	list.pointer += 1
	return list.list[list.pointer]
}

peek :: proc(list: ^token_list_t, distance: int) -> ^token.token_t {
	if list == nil || list.pointer + distance >= list.length {
		return token.generate_unknown_token()
	}
	return list.list[list.pointer + distance]
}
