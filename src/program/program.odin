package program

import "../types"

create :: proc(parent: ^types.program_t) -> (prgm: ^types.program_t, code: types.exit_codes) {
	prgm = new(types.program_t)
	if prgm == nil do return nil, .MEMORY_ALLOCATION_FAILED_IN_PROGRAM_CREATE
	prgm.length = 0
	prgm.pointer = 0
	prgm.exit = false
	prgm.breaking = false
	prgm.continueing = false
	prgm.ret_value = nil
	prgm.type = .SOURCE
	prgm.parent = parent
	return
}

add :: proc(prog: ^types.program_t, statement: ^types.syntax_t) -> (code: types.exit_codes) {
	if prog == nil do return .OBJECT_IS_NIL_IN_PROGRAM_ADD
	append(&prog.statements, statement)
	prog.length += 1
	return
}
