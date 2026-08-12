package evaluator

import "../types"

eval_global :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	return variable_declarations(syntax.value, stck, program, true)
}
