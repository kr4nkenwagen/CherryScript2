package evaluator

import "../types"

eval_while :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if syntax == nil do return .OBJECT_IS_NIL_IN_EVAL_WHILE
	for !syntax.branch.exit {
		condition := eval_primary_expression(syntax.value, stck, program) or_return
		if condition.type != .BOOL do return .CONDIION_IS_NOT_BOOL_EVAL_WHILE
		if condition.data.(bool) != true do break
		branch(syntax, stck) or_return
	}
	return .OK
}
