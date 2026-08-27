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

eval_builtin_function_args :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	ret_vals: []^types.object_t,
	code: types.exit_codes,
) {
	synt := synt.value
	ret_vals = make([]^types.object_t, len(synt.branch.statements), context.allocator)
	for i := 0; i < len(ret_vals); i += 1 {
		arg_val := eval_primary_expression(synt.branch.statements[i], stck, program) or_return
		ret_vals[i] = arg_val
	}
	return
}
