package evaluator

import "../types"
import "core:time"

eval_sleep :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	val := eval_primary_expression(syntax.value, stck, program) or_return
	seconds: f64 = 0
	if val.type == .INT {
		seconds = f64(val.data.(int))
	} else if val.type == .FLOAT {
		seconds = f64(val.data.(f32))
	} else {
		return .OBJECT_IS_UNKNOWN_TYPE
	}
	seconds = seconds * f64(time.Second)
	time.sleep(time.Duration(seconds))
	return .OK
}
