package evaluator

import "../sys"
import "../types"

eval_error :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	val, err := eval_primary_expression(syntax.value, stck, program)
	if sys.is_error(err) do return err
	eval_print(val, g_debug)
	return .OK
}
