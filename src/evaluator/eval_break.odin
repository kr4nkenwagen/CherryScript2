package evaluator

import "../types"

eval_break :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_prog := program
	for curr_prog.type != .LOOP {
		if curr_prog.parent == nil do return .BREAK_STATEMENT_NOT_IN_A_LOOP
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.exit = true
	return .OK
}
