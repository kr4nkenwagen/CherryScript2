package evaluator

import "../object"
import "../types"


eval_println :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
	debug_mode: bool,
) -> (
	code: types.exit_codes,
) {
	if syntax == nil || syntax.value == nil do return .OBJECT_IS_NIL_IN_EVAL_PRINTLN
	args := eval_builtin_function_args(syntax, stck, prgm) or_return
	if len(args) != 1 do return .INCORRECT_NUMBER_OF_PARAMETERS_IN_PRINTLN
	obj := args[0]
	if obj.type == .JSON {
		text := object.to_json_string(obj) or_return
		str_obj := object.create_string(text) or_return
		newline := object.create_string("\n") or_return
		formated_obj := object.add(str_obj, newline) or_return
		print_object(formated_obj, debug_mode) or_return
	} else {
		newline := object.create_string("\n") or_return
		formated_obj := object.add(obj, newline) or_return
		print_object(formated_obj, debug_mode) or_return
	}
	return
}
