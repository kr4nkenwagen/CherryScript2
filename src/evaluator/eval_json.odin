package evaluator

import "../object"
import "../sys"
import "../types"
import "core:os"

eval_json :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	val, err := eval_primary_expression(syntax.value, stck, program)
	if sys.is_error(err) {
		return nil, err
	}
	#partial switch (val.type) {
	case .STRING:
		return object.create_json(val.data.(string))
	case .FILE:
		file := string(val.data.(types.object_file_t).name)
		text_data, err := os.read_entire_file(file, context.allocator)
		if err != os.General_Error.None {
			return nil, .FAILED_TO_READ_FILE
		}
		defer delete(text_data)
		text := string(text_data)
		obj, obj_err := object.create_json(text)
		if sys.is_error(obj_err) {
			return nil, obj_err
		}
		if json_obj := &obj.data.(types.object_json_t); json_obj != nil {
			json_obj.file = val.data.(types.object_file_t)
		}
		return obj, .OK
	case:
		return nil, .OBJECT_IS_UNKNOWN_TYPE
	}
}
