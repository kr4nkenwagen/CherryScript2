package evaluator

import "../object"
import "../stack"
import "../types"
import "../vm"

function_identifier :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if synt == nil do return nil, .OBJECT_IS_NIL_IN_FUNCTION_IDENTIFIER
	g_current_syntax = synt
	return branch(synt, stck)
}

function_declaration :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	global: bool = false,
) -> (
	code: types.exit_codes,
) {
	if synt == nil do return .OBJECT_IS_NIL_IN_FUNCTION_DECLARATION
	g_current_syntax = synt
	funct := object.create_funct(synt.right) or_return
	funct.name = synt.right.token.literal
	curr_stack := vm.current_frame(stck) or_return
	if global {
		return stack.push(curr_stack.global_data, funct)
	}
	code = stack.push(curr_stack, funct)
	return
}
