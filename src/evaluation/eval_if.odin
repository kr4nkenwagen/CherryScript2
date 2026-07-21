package evaluation

import "../sys"
import "../types"

eval_if :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_syntax := syntax
	for curr_syntax != nil &&
	    (curr_syntax.token.type == .IF ||
			    curr_syntax.token.type == .ELSE_IF ||
			    curr_syntax.token.type == .ELSE) {
		condition, cond_err := eval_primary_expression(curr_syntax.value, vm, program)
		if sys.is_error(cond_err) &&
		   !(curr_syntax.token.type == .ELSE && cond_err == .OBJECT_IS_NIL) {
			return cond_err
		}
		if curr_syntax.token.type == .ELSE || condition.data.(bool) == true {
			_, branch_err := branch(curr_syntax, vm)
			return branch_err
		}
		curr_syntax = curr_syntax.right
	}
	return .OK
}
