package evaluator

import "../types"

eval_while :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if syntax == nil do return .OBJECT_IS_NIL
	condition := eval_primary_expression(syntax.value, stck, program) or_return
	if condition.type != .BOOL do return .TYPE_MISMATCH
	for !syntax.branch.exit && condition.data.(bool) == true {
		branch(syntax, stck) or_return
		condition = eval_primary_expression(syntax.value, stck, program) or_return
	}
	return .OK
}
