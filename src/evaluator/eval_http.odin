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
	g_current_syntax = syntax
	type := syntax.value.token.literal
	args: []^types.object_t
	defer delete(args)
	if syntax.value.value != nil {
		args = eval_builtin_function_args(syntax.value.value, stck, program) or_return
	}
	switch type {
	case "get":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_GET
		return eval_get(args[0])
	case "post":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_POST
		return eval_post(args[0])
	case "update":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_UPDATE
		return eval_update(args[0])
	case "put":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_PUT
		return eval_put(args[0])
	case "delete":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_DELETE
		return eval_delete(args[0])
	case "patch":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_PATCH
		return eval_patch(args[0])
	case "head":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_HEAD
		return eval_head(args[0])
	case "options":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_OPTIONS
		return eval_options(args[0])
	case "trace":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_TRACE
		return eval_trace(args[0])
	case "connect":
		if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_HTTP_CONNECT
		return eval_connect(args[0])
	case:
		code = .UNEXPECTED_MEMBER_IN_EVAL_HTTP
	}
	return
}
