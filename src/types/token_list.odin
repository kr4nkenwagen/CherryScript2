package types 

token_list_t :: struct {
	list:    [dynamic]^token_t,
	length:  int,
	pointer: int,
}
