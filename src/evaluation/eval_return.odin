package evaluation

import "../sys"
import "../types"

eval_return :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_prog := program
	for curr_prog.type != .FUNCTION {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.exit = true

	val, err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(err) do return err

	curr_prog.ret_value = val
	return .OK
}
