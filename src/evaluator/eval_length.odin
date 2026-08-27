package evaluator

import "../object"
import "../types"

eval_length :: proc(
	sntx: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	args := eval_builtin_function_args(sntx, stck, prgm) or_return
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_LEN
	length := object.length(args[0]) or_return
	ret_obj = object.create_int(length) or_return
	return
}
