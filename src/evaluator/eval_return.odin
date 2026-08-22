package evaluator

import "../types"

eval_return :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if program == nil do return .OBJECT_IS_NIL_IN_EVAL_RETURN
	curr_prog := program
	for curr_prog.type != .FUNCTION && curr_prog.type != .SOURCE {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.exit = true
	if syntax.value == nil do return .OK
	val := eval_primary_expression(syntax.value, stck, program) or_return
	curr_prog.ret_value = val
	return
}
