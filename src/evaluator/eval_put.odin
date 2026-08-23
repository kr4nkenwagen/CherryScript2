package evaluator

import "../http"
import "../object"
import "../types"


eval_put :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	g_current_syntax = syntax
	val := eval_primary_expression(syntax.value, stck, program) or_return
	if val.type != .JSON do return nil, .UNSUPPORTED_OBJECT_TYPE_IN_EVAL_PUT
	body := object.json_get(val, "body") or_return
	body_data: string
	url := object.json_get(val, "url") or_return
	header_data: string
	header := object.json_get(val, "head") or_return
	if header.type != .NULL {
		if header.type != .JSON do return nil, .HEADER_IS_NOT_JSON_IN_EVAL_PUT
		if len(header.data.(types.object_json_t).value) > 0 {
			header_data = object.to_json_string(header) or_return
		}
	}
	if body.type == .STRING do body_data = body.data.(string)
	else if body.type == .JSON do body_data = object.to_json_string(body) or_return
	else do return nil, .BODY_NEEDS_TO_BE_STRING_OR_JSON_IN_EVAL_PUT
	ret_body, ret_head := http.put(url.data.(string), header_data, body_data) or_return
	obj = object.create_http_response(ret_body, ret_head) or_return
	return
}
