package evaluator

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"

// Fetches the base variable/identifier object from the current stack frame
eval_base_identifier :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	curr_stack, curr_stack_err := vm.current_frame(stck)
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

	return obj, .OK
}

// Evaluates property access (.member) on a JSON object
eval_member_access :: proc(
	obj: ^types.object_t,
	member_synt: ^types.syntax_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if obj.type != .JSON {
		return nil, .INTERPRETER_ERROR
	}
	return object.json_get(obj, member_synt.token.literal)
}

// Evaluates array index access ([expr]) on an ARRAY object
eval_index_access :: proc(
	obj: ^types.object_t,
	index_synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if obj.type != .ARRAY {
		return nil, .EXPECTED_ARRAY_INDEX
	}

	index_obj, index_err := eval_primary_expression(index_synt, stck, prog)
	if sys.is_error(index_err) {
		return nil, index_err
	}

	if index_obj == nil || index_obj.type != .INT {
		return nil, .EXPECTED_ARRAY_INDEX
	}

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
	if synt.left == nil {
		return obj, .OK
	}

	if obj.type != .FUNCTION {
		return nil, .INTERPRETER_ERROR
	}

	converted_ptr := transmute(^types.syntax_t)obj.data.(rawptr)
	converted_ptr.value = synt.left
	return function_identifier(converted_ptr, stck)
}

// Main evaluation procedure: iteratively resolves chained identifiers, members, and array indices
eval_identifier :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	curr_obj, base_err := eval_base_identifier(synt, stck)
	if sys.is_error(base_err) {
		return nil, base_err
	}

	curr_synt := synt

	// Walk through nested child nodes (.value) across mixed types
	for curr_synt.value != nil {
		curr_synt = curr_synt.value

		#partial switch curr_obj.type {
		case .JSON:
			next_obj, member_err := eval_member_access(curr_obj, curr_synt)
			if sys.is_error(member_err) {
				return nil, member_err
			}
			curr_obj = next_obj

		case .ARRAY:
			next_obj, index_err := eval_index_access(curr_obj, curr_synt, stck, prog)
			if sys.is_error(index_err) {
				return nil, index_err
			}
			curr_obj = next_obj

		case:
			return nil, .INTERPRETER_ERROR
		}
	}

	return eval_function_call(curr_obj, synt, stck)
}
