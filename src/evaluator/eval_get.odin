package evaluator

import "../http"
import "../object"
import "../sys"
import "../types"

eval_get :: proc(
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
	if val.type != .STRING {
		return nil, .ERROR
	}
	res, res_err := http.get(val.data.(string))
	if sys.is_error(res_err) {
		return nil, res_err
	}
	return object.create_json(res)
}
