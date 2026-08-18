package evaluator

import "../stack"
import "../sys"
import "../types"
import "../vm"

eval_for :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if syntax == nil do return .OBJECT_IS_NIL
	new_stack := stack.create() or_return
	vm.push_frame(stck, new_stack, true) or_return
	_, init_err := eval_primary_expression(syntax.left, stck, program)
	if sys.is_error(init_err) {
		vm.pop_frame(stck) or_return
		return init_err
	}
	condition, cond_err := eval_primary_expression(syntax.value, stck, program)
	if sys.is_error(cond_err) {
		vm.pop_frame(stck) or_return
		return cond_err
	}
	if condition.type != .BOOL {
		return .TYPE_MISMATCH
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
