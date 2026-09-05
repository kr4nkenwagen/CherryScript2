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
	if synt == nil do return .OBJECT_IS_NIL_IN_VARIABLE_DECLARATION
	prog.stats.current_syntax = synt
	is_const := synt.token.type == .CONST
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack := vm.current_frame(stck) or_return
		obj := stack.get(curr_stack, curr.token.literal) or_return
		if obj != nil do return .REDECLARATION_ERROR_IN_VARIABLE_DECLARATION
		obj = eval_primary_expression(curr.value, stck, prog) or_return
		if must_copy_value(curr.value) {
			obj = object.copy_deep(obj) or_return
		}
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
	return
}

must_copy_value :: proc(value: ^types.syntax_t) -> bool {
	if value == nil do return true
	#partial switch value.token.type {
	case .NUMBER, .STRING_WRAPPER, .TRUE, .FALSE, .NULL:
		return false
	}
	return true
}

eval_variable_remove :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if synt == nil {
		return .OBJECT_IS_NIL_IN_EVAL_VARIABLE_REMOVE
	}
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack := vm.current_frame(stck) or_return
		obj := stack.get(curr_stack, curr.token.literal) or_return
		if obj != nil do stack.remove_object(curr_stack, curr.token.literal)
		curr = curr.left
	}
	return
}

eval_array_declaration :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if synt == nil do return nil, .OBJECT_IS_NIL_EVAL_ARRAY_DECLARATION
	ret_obj = object.create_array() or_return
	curr := synt.left
	for curr != nil {
		obj := eval_primary_expression(curr, stck, prog) or_return
		object.array_set(ret_obj, ret_obj.data.(types.object_array_t).count, obj) or_return
		curr = curr.right
	}
	return
}
