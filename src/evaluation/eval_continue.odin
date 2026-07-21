package evaluation

import "../types"

eval_continue :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_prog := program
	for curr_prog.type != .LOOP {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.continueing = true
	return .OK
}
