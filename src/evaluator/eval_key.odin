package evaluator

import "../predefined_functions"
import "../types"

eval_key :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	return predefined_functions.key_func()
}
