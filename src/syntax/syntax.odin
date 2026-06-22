package syntax

import "../token"

syntax_t :: struct {
	token:  ^token.token_t,
	left:   ^syntax_t,
	right:  ^syntax_t,
	value:  ^syntax_t,
	branch: ^rawptr,
	args:   ^rawptr,
}

create :: proc() -> (^syntax_t, bool) {
	syntax := new(syntax_t)
	if syntax == nil {
		return nil, true
	}
	return syntax, false
}
