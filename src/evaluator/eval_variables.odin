package evaluator

import "../object"
import "../stack"
import "../types"
import "../vm"

variable_declarations :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
	global: bool = false,
) -> (
	code: types.exit_codes,
) {
	if synt == nil do return .OBJECT_IS_NIL
	is_const := synt.token.type == .CONST
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack := vm.current_frame(stck) or_return
		obj := stack.get(curr_stack, curr.token.literal) or_return
		if obj != nil do return .REDECLARATION_ERROR
		obj = eval_primary_expression(curr.value, stck, prog) or_return
		obj.name = curr.token.literal
		obj.is_const = is_const
		curr_stack = vm.current_frame(stck) or_return
		if !global {
			stack.push(curr_stack, obj) or_return
		} else {
			stack.push(curr_stack.global_data, obj) or_return
		}
		curr = curr.left
	}
	return .OK
}

eval_variable_remove :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack := vm.current_frame(stck) or_return
		obj := stack.get(curr_stack, curr.token.literal) or_return
		if obj != nil do stack.remove_object(curr_stack, curr.token.literal)
		curr = curr.left
	}
	return .OK
}

eval_array_declaration :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if synt == nil do return nil, .OBJECT_IS_NIL
	arr := object.create_array() or_return
	curr := synt.left
	for curr != nil {
		obj := eval_primary_expression(curr, stck, prog) or_return
		object.array_set(arr, arr.data.(types.object_array_t).count, obj) or_return
		curr = curr.right
	}
	return arr, .OK
}
