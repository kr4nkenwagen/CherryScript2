package evaluator

import "../predefined_functions"
import "../types"

eval_in :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	predefined_functions.in_func()
	return .OK
}
