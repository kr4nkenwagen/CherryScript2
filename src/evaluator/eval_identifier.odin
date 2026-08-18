package evaluator

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"

eval_base_identifier :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	curr_stack := vm.current_frame(stck) or_return
	obj := stack.get(curr_stack, synt.token.literal) or_return
	if obj == nil do return nil, .IDENTIFIER_DOES_NOT_EXIST

	return obj, .OK
}

eval_member_access :: proc(
	obj: ^types.object_t,
	member_synt: ^types.syntax_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if obj.type != .JSON do return nil, .INTERPRETER_ERROR
	return object.json_get(obj, member_synt.token.literal)
}

eval_index_access :: proc(
	obj: ^types.object_t,
	index_synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if obj.type != .ARRAY do return nil, .EXPECTED_ARRAY_INDEX
	index_obj: ^types.object_t
	index_err: types.exit_codes
	if (index_synt.token.type == .IDENTIFIER) {
		curr_stack := vm.current_frame(stck) or_return
		index_obj = stack.get(curr_stack, index_synt.token.literal) or_return
	} else do index_obj = eval_primary_expression(index_synt, stck, prog) or_return
	if index_obj == nil || index_obj.type != .INT do return nil, .EXPECTED_ARRAY_INDEX
	idx := int(index_obj.data.(int))
	return object.array_get(obj, idx)
}

eval_function_call :: proc(
	obj: ^types.object_t,
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if synt.left == nil do return obj, .OK

	if obj.type != .FUNCTION do return nil, .INTERPRETER_ERROR

	converted_ptr := transmute(^types.syntax_t)obj.data.(rawptr)
	converted_ptr.value = synt.left
	return function_identifier(converted_ptr, stck)
}

eval_identifier :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	curr_obj := eval_base_identifier(synt, stck) or_return
	curr_synt := synt
	for curr_synt.value != nil {
		curr_synt = curr_synt.value
		#partial switch curr_obj.type {
		case .JSON:
			next_obj := eval_member_access(curr_obj, curr_synt) or_return
			curr_obj = next_obj

		case .ARRAY:
			next_obj := eval_index_access(curr_obj, curr_synt, stck, prog) or_return
			curr_obj = next_obj

		case:
			return nil, .INTERPRETER_ERROR
		}
	}
	return eval_function_call(curr_obj, synt, stck)
}
