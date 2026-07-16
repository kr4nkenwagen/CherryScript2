package program

import "../types"

create :: proc(parent: ^types.program_t) -> (^types.program_t, bool) {
	prog := new(types.program_t)
	if prog == nil {
		return nil, true
	}
	prog.length = 0
	prog.pointer = 0
	prog.exit = false
	prog.breaking = false
	prog.continueing = false
	prog.ret_value = nil
	prog.type = types.program_type_t.SOURCE
	prog.parent = parent
	return prog, false
}

add :: proc(prog: ^types.program_t, statement: ^types.syntax_t) -> bool {
	if prog == nil || statement == nil {
		return true
	}
	append(&prog.statements, statement)
	prog.length += 1
	return false
}
