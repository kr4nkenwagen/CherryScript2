package evaluation

import "../predefined_functions"
import "../sys"
import "../types"

eval_out :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	val, err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(err) do return err
	predefined_functions.print(val)
	return .OK
}
