package evaluator

import "../stack"
import "../sys"
import "../types"
import "../vm"

eval_for :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if syntax == nil {
		return .OBJECT_IS_NIL
	}
	new_stack, new_stack_err := stack.create()
	if sys.is_error(new_stack_err) {
		return new_stack_err
	}
	err := vm.push_frame(stck, new_stack, true)
	if sys.is_error(err) {
		return err
	}
	_, init_err := eval_primary_expression(syntax.left, stck, program)
	if sys.is_error(init_err) {
		err = vm.pop_frame(stck)
		if sys.is_error(err) {
			return err
		}
		return init_err
	}
	condition, cond_err := eval_primary_expression(syntax.value, stck, program)
	if sys.is_error(cond_err) {
		err = vm.pop_frame(stck)
		if sys.is_error(err) {
			return err
		}
		return cond_err
	}
	if condition.type != .BOOL {
		return .TYPE_MISMATCH
	}
	for !syntax.branch.exit && condition.data.(bool) == true {
		_, branch_err := branch(syntax, stck)
		if sys.is_error(branch_err) {
			return branch_err
		}
		_, post_err := eval_primary_expression(syntax.right, stck, program)
		if sys.is_error(post_err) {
			return post_err
		}
		condition, cond_err = eval_primary_expression(syntax.value, stck, program)
		if sys.is_error(cond_err) {
			return cond_err
		}
	}
	syntax.branch.exit = false
	err = vm.pop_frame(stck)
	if sys.is_error(err) {
		return err
	}
	return .OK
}
