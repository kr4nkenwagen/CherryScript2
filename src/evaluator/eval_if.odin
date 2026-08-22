package evaluator

import "../sys"
import "../types"

eval_if :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	curr_syntax := syntax
	for curr_syntax != nil &&
	    (curr_syntax.token.type == .IF ||
			    curr_syntax.token.type == .ELSE_IF ||
			    curr_syntax.token.type == .ELSE) {
		condition, cond_err := eval_primary_expression(curr_syntax.value, stck, program)
		if curr_syntax.token.type != .ELSE && cond_err != .OBJECT_IS_NIL_IN_EVAL_IF {
			if sys.is_error(cond_err) do return cond_err
		}
		if curr_syntax.token.type == .ELSE || condition.data.(bool) == true {
			_, branch_err := branch(curr_syntax, stck)
			return branch_err
		}
		curr_syntax = curr_syntax.right
	}
	return
}
