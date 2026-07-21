package evaluator

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"

function_identifier :: proc(
	synt: ^types.syntax_t,
	vmem: ^types.vm_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL
	}
	return branch(synt, vmem)
}

function_declaration :: proc(synt: ^types.syntax_t, vmem: ^types.vm_t) -> types.exit_codes {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	funct, funct_err := object.create_funct(synt.right)
	if sys.is_error(funct_err) {
		return funct_err
	}
	funct.name = synt.right.token.literal
	curr_stack, curr_stack_err := vm.current_frame(vmem)
	if sys.is_error(curr_stack_err) {
		return curr_stack_err
	}
	return stack.push(curr_stack, funct)
}
