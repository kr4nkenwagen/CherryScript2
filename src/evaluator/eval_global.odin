package evaluator

import "../types"

eval_global :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if syntax.value.token.type == .VAR || syntax.value.token.type == .CONST do return variable_declarations(syntax.value, stck, program, true)
	if syntax.value.token.type == .FUNCTION do return function_declaration(syntax.value, stck, true)
	code = .OBJECT_NOT_VARIABLE_OR_FUNCTION_CANT_BE_GLOBAL_IN_EVAL_GLOBAL
	return
}
