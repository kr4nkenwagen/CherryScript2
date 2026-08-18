package evaluator

import "../object"
import "../sys"
import "../types"

eval_length :: proc(obj: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	length := object.length(obj) or_return
	return object.create_int(length)
}
