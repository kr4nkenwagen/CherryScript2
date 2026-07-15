package types

syntax_t :: struct {
	token:  ^token_t,
	left:   ^syntax_t,
	right:  ^syntax_t,
	value:  ^syntax_t,
	branch: ^program_t,
	args:   ^rawptr,
}
