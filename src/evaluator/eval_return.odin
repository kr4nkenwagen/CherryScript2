package evaluator

import "../sys"
import "../types"

eval_return :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if program == nil {
		return .OBJECT_IS_NIL
	}
	curr_prog := program
	for curr_prog.type != .FUNCTION && curr_prog.type != .SOURCE {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.exit = true
	if syntax.value == nil {
		return .OK
	}
	val, err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(err) {
		return err
	}
	curr_prog.ret_value = val
	return .OK
}
