package program

import "../syntax"

type_t :: enum {
	SOURCE,
	LOOP,
	FUNCTION,
	IF,
}

program_t :: struct {
	exit:        bool,
	breaking:    bool,
	continueing: bool,
	pointer:     int,
	type:        type_t,
	length:      int,
	parent:      ^program_t,
	statements:  ^syntax.syntax_t,
}
