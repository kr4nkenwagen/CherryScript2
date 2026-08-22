package evaluator

import "../types"

eval_error :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	val := eval_primary_expression(syntax.value, stck, program) or_return
	eval_print(val, g_debug)
	return
}
