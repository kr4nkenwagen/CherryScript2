package evaluator

import "../types"

eval_out :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	g_current_syntax = syntax
	eval_print(syntax, stck, program, g_debug)
	return
}
