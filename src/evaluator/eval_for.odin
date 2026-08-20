package evaluator

import "../stack"
import "../types"
import "../vm"

eval_for :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if syntax == nil do return .OBJECT_IS_NIL_IN_EVAL_FOR
	if syntax.left == nil && syntax.right == nil {
		return eval_while(syntax, stck, program)
	}
	new_stack := stack.create() or_return
	vm.push_frame(stck, new_stack, true) or_return
	eval_primary_expression(syntax.left, stck, program) or_return
	condition := eval_primary_expression(syntax.value, stck, program) or_return
	if condition.type != .BOOL {
		return .CONDITION_IS_NOT_BOOL_IN_EVAL_FOR
	}

	for !syntax.branch.exit && condition.data.(bool) == true {
		branch(syntax, stck) or_return
		eval_primary_expression(syntax.right, stck, program) or_return
		condition = eval_primary_expression(syntax.value, stck, program) or_return
	}
	syntax.branch.exit = false
	vm.pop_frame(stck) or_return
	return .OK
}
