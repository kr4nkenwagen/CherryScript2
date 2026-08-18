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
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	val := eval_primary_expression(syntax.value, stck, program) or_return
	#partial switch (val.type) {
	case .STRING:
		return object.create_json(val.data.(string))
	case .FILE:
		file := string(val.data.(types.object_file_t).name)
		if !os.exists(file) {
			_, err := os.create(file)
			if err != os.General_Error.None do return nil, .FAILED_TO_READ_FILE
			err = os.write_entire_file(file, "{}")
			if err != os.General_Error.None do return nil, .FAILED_TO_READ_FILE
		}
		obj := object.create_json_from_file(file) or_return
		if json_obj := &obj.data.(types.object_json_t); json_obj != nil do json_obj.file = val.data.(types.object_file_t)
		return obj, .OK
	case:
		return nil, .OBJECT_IS_UNKNOWN_TYPE
	}
}
