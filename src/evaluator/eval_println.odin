package evaluator

import "../object"
import "../types"


eval_println :: proc(obj: ^types.object_t, debug_mode: bool) -> (code: types.exit_codes) {
	if obj == nil do return .OBJECT_IS_NIL
	newline := object.create_string("\n") or_return
	formated_obj := object.add(obj, newline) or_return
	return eval_print(formated_obj, debug_mode)
}
