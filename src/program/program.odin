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
	statements:  [dynamic]^syntax.syntax_t,
	ret_value:   rawptr,
}

create :: proc(parent: ^program_t) -> (^program_t, bool) {
	if parent == nil {
		return nil, true
	}
	prog := new(program_t)
	if prog == nil {
		return nil, true
	}
	prog.length = 0
	prog.pointer = 0
	prog.exit = false
	prog.breaking = false
	prog.continueing = false
	prog.ret_value = nil
	prog.type = type_t.SOURCE
	prog.parent = parent
	return prog, false
}

add :: proc(prog: ^program_t, statement: ^syntax.syntax_t) -> bool {
	if prog == nil || statement == nil {
		return true
	}
	prog.statements[prog.length] = statement
	prog.length += 1
	return false
}
