package evaluator

import "../object"
import "../sys"
import "../types"

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
		obj, obj_err := object.create_json(val.data.(string))
		return obj, obj_err
	case:
		return nil, .OBJECT_IS_UNKNOWN_TYPE
	}
}
