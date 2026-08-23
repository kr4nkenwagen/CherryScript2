package evaluator

import "../types"

eval_continue :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	g_current_syntax = syntax
	curr_prog := program
	for curr_prog.type != .LOOP {
		if curr_prog.parent == nil {
			return .CONTINUE_STATEMENT_NOT_IN_A_LOOP
		}
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.continueing = true
	return
}
