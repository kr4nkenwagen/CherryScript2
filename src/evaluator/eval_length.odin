package evaluator

import "../object"
import "../types"

eval_length :: proc(obj: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	length := object.length(obj) or_return
	ret_obj = object.create_int(length) or_return
	return
}
