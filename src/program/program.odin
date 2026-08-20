package program

import "../types"

create :: proc(parent: ^types.program_t) -> (prgm: ^types.program_t, code: types.exit_codes) {
	prog := new(types.program_t)
	if prog == nil do return nil, .MEMORY_ALLOCATION_FAILED_IN_PROGRAM_CREATE
	prog.length = 0
	prog.pointer = 0
	prog.exit = false
	prog.breaking = false
	prog.continueing = false
	prog.ret_value = nil
	prog.type = .SOURCE
	prog.parent = parent
	return prog, .OK
}

add :: proc(prog: ^types.program_t, statement: ^types.syntax_t) -> (code: types.exit_codes) {
	if prog == nil do return .OBJECT_IS_NIL_IN_PROGRAM_ADD
	append(&prog.statements, statement)
	prog.length += 1
	return .OK
}
