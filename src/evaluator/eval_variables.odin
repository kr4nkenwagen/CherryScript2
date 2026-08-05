package evaluator

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"
import "vendor:stb/rect_pack"

variable_declarations :: proc(
	synt: ^types.syntax_t,
	vmem: ^types.vm_t,
	prog: ^types.program_t,
) -> types.exit_codes {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	is_const := synt.token.type == .CONST
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack, curr_stack_err := vm.current_frame(vmem)
		if sys.is_error(curr_stack_err) {
			return curr_stack_err
		}
		obj, obj_err := stack.get(curr_stack, curr.token.literal)
		if sys.is_error(obj_err) {
			return obj_err
		}
		if obj != nil {
			return .REDECLARATION_ERROR
		}
		obj, obj_err = eval_primary_expression(curr.value, vmem, prog)
		if sys.is_error(obj_err) {
			return obj_err
		}

		obj.name = curr.token.literal
		obj.is_const = is_const
		curr_stack, curr_stack_err = vm.current_frame(vmem)
		if sys.is_error(curr_stack_err) {
			return curr_stack_err
		}
		stack_err := stack.push(curr_stack, obj)
		if sys.is_error(stack_err) {
			return stack_err
		}
		curr = curr.left
	}
	return .OK
}

eval_variable_remove :: proc(
	synt: ^types.syntax_t,
	vmem: ^types.vm_t,
	prog: ^types.program_t,
) -> types.exit_codes {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack, curr_stack_err := vm.current_frame(vmem)
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
	vmem: ^types.vm_t,
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
		obj, obj_err := eval_primary_expression(curr, vmem, prog)
		if sys.is_error(obj_err) {
			return nil, obj_err
		}
		obj_err = object.array_set(arr, arr.data.(types.object_array_t).count, obj)
		if sys.is_error(obj_err) {
			return nil, obj_err
		}
		curr = curr.left
	}

	return arr, .OK
}

eval_array_identifier :: proc(
	synt: ^types.syntax_t,
	vmem: ^types.vm_t,
	obj: ^types.object_t,
	prog: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	index, index_err := eval_primary_expression(synt.value, vmem, prog)
	if sys.is_error(index_err) {
		return nil, index_err
	}
	if index.type != .INT {
		return nil, .EXPECTED_ARRAY_INDEX
	}
	return object.array_get(obj, int(index.data.(int)))
}

eval_identifier :: proc(
	synt: ^types.syntax_t,
	vmem: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	curr_stack, curr_stack_err := vm.current_frame(vmem)
	if sys.is_error(curr_stack_err) {
		return nil, curr_stack_err
	}
	obj, obj_err := stack.get(curr_stack, synt.token.literal)
	if sys.is_error(obj_err) {
		return nil, obj_err
	}
	if obj == nil {
		return nil, .IDENTIFIER_DOES_NOT_EXIST
	}
	if obj.type == .ARRAY {
		return eval_array_identifier(synt, vmem, obj, prog)
	}
	if obj.type == .FUNCTION {
		if synt.left == nil {
			return nil, .INTERPRETER_ERROR
		}
		converted_ptr := transmute(^types.syntax_t)obj.data.(rawptr)
		converted_ptr.value = synt.left
		return function_identifier(converted_ptr, vmem)
	}
	return obj, .OK
}
