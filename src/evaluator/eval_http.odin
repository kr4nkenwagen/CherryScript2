package evaluator

import "../types"

eval_http :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	type := syntax.value.token.literal
	switch type {
	case "get":
		return eval_get(syntax.value, stck, program)
	case "post":
		return eval_post(syntax.value, stck, program)
	case "update":
		return eval_update(syntax.value, stck, program)
	case "put":
		return eval_put(syntax.value, stck, program)
	case "delete":
		return eval_delete(syntax.value, stck, program)
	case "patch":
		return eval_patch(syntax.value, stck, program)
	case "head":
		return eval_head(syntax.value, stck, program)
	case "options":
		return eval_options(syntax.value, stck, program)
	case "trace":
		return eval_trace(syntax.value, stck, program)
	case "connect":
		return eval_connect(syntax.value, stck, program)
	case:
		code = .UNEXPECTED_MEMBER_IN_EVAL_HTTP
	}
	return
}
