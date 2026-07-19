package program

import "../types"

create :: proc(parent: ^types.program_t) -> (^types.program_t, types.exit_codes) {
	prog := new(types.program_t)
	if prog == nil {
		return nil, types.exit_codes.MEMORY_ALLOCATION_FAILED
	}
	prog.length = 0
	prog.pointer = 0
	prog.exit = false
	prog.breaking = false
	prog.continueing = false
	prog.ret_value = nil
	prog.type = types.program_type_t.SOURCE
	prog.parent = parent
	return prog, types.exit_codes.OK
}

add :: proc(prog: ^types.program_t, statement: ^types.syntax_t) -> types.exit_codes {
	if prog == nil {
		return types.exit_codes.OBJECT_IS_NIL
	}
	append(&prog.statements, statement)
	prog.length += 1
	return types.exit_codes.OK
}
