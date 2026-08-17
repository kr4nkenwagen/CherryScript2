package evaluator

import "../object"
import "../sys"
import "../types"


eval_println :: proc(obj: ^types.object_t, debug_mode: bool) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	newline, newline_err := object.create_string("\n")
	if sys.is_error(newline_err) {
		return newline_err
	}
	formated_obj, formated_obj_err := object.add(obj, newline)
	if sys.is_error(formated_obj_err) {
		return formated_obj_err
	}
	return eval_print(formated_obj, debug_mode)
}
