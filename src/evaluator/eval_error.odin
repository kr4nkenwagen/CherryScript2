package evaluator

import "../types"

eval_error :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	g_current_syntax = syntax
	eval_print(syntax, stck, program, false)
	return
}
