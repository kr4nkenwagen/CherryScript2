package evaluator

import "../sys"
import "../types"
import "core:fmt"
import "core:time"

eval_sleep :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	val, err := eval_primary_expression(syntax.value, stck, program)
	if sys.is_error(err) {
		return err
	}
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
	fmt.printf("%f\n", seconds)
	return .OK
}
