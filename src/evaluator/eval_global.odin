package evaluator

import "../types"

eval_global :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if syntax.value.token.type == .VAR || syntax.value.token.type == .CONST {
		return variable_declarations(syntax.value, stck, program, true)
	}
	if syntax.value.token.type == .FUNCTION {
		return function_declaration(syntax.value, stck, true)
	}
	return .UNEXPECTED_SYNTAX
}
