package evaluator

import "../object"
import "../types"

eval_exists :: proc(obj: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if obj == nil {
		return nil, .OBJECT_IS_NIL_IN_EVAL_EXISTS
	}
	file: string
	#partial switch (obj.type) {
	case .FILE:
		file = obj.data.(types.object_file_t).name
	case .JSON:
		file = obj.data.(types.object_json_t).file.name
	case:
		return nil, .UNEXPECTED_OBJECT_TYPE_IN_EVAL_EXISTS
	}
	res := object.file_exists(file) or_return
	ret_obj, code = object.create_bool(res)
	return
}
