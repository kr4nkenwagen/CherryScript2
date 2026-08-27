package evaluator

import "../object"
import "../types"

eval_exists :: proc(
	sntx: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	args := eval_builtin_function_args(sntx, stck, prgm) or_return
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_EXISTS
	if args[0] == nil do return nil, .OBJECT_IS_NIL_IN_EVAL_EXISTS
	obj := args[0]
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
