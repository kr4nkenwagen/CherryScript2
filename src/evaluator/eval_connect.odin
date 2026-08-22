package evaluator

import "../http"
import "../object"
import "../types"

eval_connect :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	val := eval_primary_expression(syntax.value, stck, program) or_return
	body_ret: string
	ret_head: string
	if val.type == .STRING {
		body_ret, ret_head = http.connect(val.data.(string)) or_return
	} else if val.type == .JSON {
		url := object.json_get(val, "url") or_return
		header := object.json_get(val, "head") or_return
		if len(header.data.(types.object_json_t).value) > 0 {
			header_data := object.to_json_string(header) or_return
			body_ret, ret_head = http.connect(url.data.(string), header_data) or_return
		} else {
			body_ret, ret_head = http.connect(url.data.(string)) or_return
		}
	} else {
		return nil, .UNSUPPORTED_OBJECT_TYPE_IN_EVAL_CONNECT
	}
	obj = object.create_http_response(body_ret, ret_head) or_return
	return
}
