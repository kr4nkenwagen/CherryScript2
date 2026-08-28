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
	val := eval_primary_expression(syntax.value, stck, program) or_return
	print_object(val, g_debug)
	return
}
