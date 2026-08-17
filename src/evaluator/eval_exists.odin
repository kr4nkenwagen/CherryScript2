package evaluator

import "../object"
import "../sys"
import "../types"

eval_exists :: proc(obj: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	file: string
	#partial switch (obj.type) {
	case .FILE:
		file = obj.data.(types.object_file_t).name
	case .JSON:
		file = obj.data.(types.object_json_t).file.name
	case:
		return nil, .ERROR
	}
	res, res_err := object.file_exists(file)
	if sys.is_error(res_err) {
		return nil, res_err
	}
	return object.create_bool(res)
}
