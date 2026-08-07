package evaluator

import "../sys"
import "../types"

eval_while :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if syntax == nil {
		return .OBJECT_IS_NIL
	}
	condition, cond_err := eval_primary_expression(syntax.value, stck, program)
	if sys.is_error(cond_err) {
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
		condition, cond_err = eval_primary_expression(syntax.value, stck, program)
		if sys.is_error(cond_err) {
			return cond_err
		}
	}
	return .OK
}
