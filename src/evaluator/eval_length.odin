package evaluator

import "../object"
import "../sys"
import "../types"

eval_length :: proc(obj: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	length, length_err := object.length(obj)
	if sys.is_error(length_err) {
		return nil, length_err
	}
	return object.create_int(length)
}
