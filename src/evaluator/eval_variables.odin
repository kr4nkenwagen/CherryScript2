package evaluator

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"

variable_declarations :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
	global: bool = false,
) -> types.exit_codes {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	is_const := synt.token.type == .CONST
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack, curr_stack_err := vm.current_frame(stck)
		if sys.is_error(curr_stack_err) {
			return curr_stack_err
		}
		obj, obj_err := stack.get(curr_stack, curr.token.literal)
		if sys.is_error(obj_err) {
			return obj_err
		}
		if obj != nil {
			fmt.printf("%s\n", obj.name)
			return .REDECLARATION_ERROR
		}
		obj, obj_err = eval_primary_expression(curr.value, stck, prog)
		if sys.is_error(obj_err) {
			return obj_err
		}
		obj.name = curr.token.literal
		obj.is_const = is_const
		curr_stack, curr_stack_err = vm.current_frame(stck)
		if sys.is_error(curr_stack_err) {
			return curr_stack_err
		}
		if !global {
			stack_err := stack.push(curr_stack, obj)
			if sys.is_error(stack_err) {
				return stack_err
			}
		} else {
			stack_err := stack.push(curr_stack.global_data, obj)
			if sys.is_error(stack_err) {
				return stack_err
			}
		}
		curr = curr.left
	}
	return .OK
}

import "core:fmt"

eval_variable_remove :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> types.exit_codes {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack, curr_stack_err := vm.current_frame(stck)
		if sys.is_error(curr_stack_err) {
			return curr_stack_err
		}
		obj, obj_err := stack.get(curr_stack, curr.token.literal)
		if sys.is_error(obj_err) {
			return obj_err
		}
		if obj != nil {
			stack.remove_object(curr_stack, curr.token.literal)
		}
		curr = curr.left
	}
	return .OK
}

eval_array_declaration :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL
	}
	arr, arr_err := object.create_array()
	if sys.is_error(arr_err) {
		return nil, arr_err
	}
	curr := synt.left
	for curr != nil {
		obj, obj_err := eval_primary_expression(curr, stck, prog)
		if sys.is_error(obj_err) {
			return nil, obj_err
		}
		obj_err = object.array_set(arr, arr.data.(types.object_array_t).count, obj)
		if sys.is_error(obj_err) {
			return nil, obj_err
		}
		curr = curr.right
	}
	return arr, .OK
}
