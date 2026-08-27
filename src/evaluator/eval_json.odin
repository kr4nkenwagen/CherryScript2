package evaluator

import "../object"
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
	g_current_syntax = syntax
	args := eval_builtin_function_args(syntax, stck, program) or_return
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_JSON
	val := args[0]
	#partial switch (val.type) {
	case .STRING:
		return object.create_json(val.data.(string))
	case .FILE:
		file := string(val.data.(types.object_file_t).name)
		if !os.exists(file) {
			_, err := os.create(file)
			if err != os.General_Error.None do return nil, .FAILED_TO_CREATE_FILE_IN_EVAL_JSON
			err = os.write_entire_file(file, "{}")
			if err != os.General_Error.None do return nil, .FAILED_TO_WRITE_FILE_IN_EVAL_JSON
		}
		obj := object.create_json_from_file(file) or_return
		if json_obj := &obj.data.(types.object_json_t); json_obj != nil do json_obj.file = val.data.(types.object_file_t)
		return obj, .OK
	case:
		code = .OBJECT_IS_NOT_SUPPORTED_IN_EVAL_JSON
	}
	return
}
