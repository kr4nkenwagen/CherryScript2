package evaluator

import "../http"
import "../object"
import "../types"

eval_get :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	val := eval_primary_expression(syntax.value, stck, program) or_return
	if val.type != .STRING do return nil, .OBJECT_IS_NOT_STRING_IN_EVAL_GET
	res := http.get(val.data.(string)) or_return
	return object.create_json(res)
}
