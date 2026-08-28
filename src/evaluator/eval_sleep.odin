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
	program.stats.current_syntax = syntax
	val := eval_primary_expression(syntax.value, stck, program) or_return
	seconds: f64 = 0
	if val.type == .INT {
		seconds = f64(val.data.(int))
	} else if val.type == .FLOAT {
		seconds = f64(val.data.(f32))
	} else {
		return .VALUE_IS_NOT_NUMERICAL_VALUE_IN_EVAL_SLEEP
	}
	seconds = seconds * f64(time.Second)
	time.sleep(time.Duration(seconds))
	return
}
