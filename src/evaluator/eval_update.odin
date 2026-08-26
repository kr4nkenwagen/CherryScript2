package evaluator

import "../http"
import "../object"
import "../types"

eval_update :: proc(obj: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if obj.type != .JSON do return nil, .UNSUPPORTED_OBJECT_TYPE_IN_EVAL_UPDATE
	body := object.json_get(obj, "body") or_return
	body_data: string
	url := object.json_get(obj, "url") or_return
	header_data: string
	header := object.json_get(obj, "head") or_return
	if header.type != .NULL {
		if header.type != .JSON do return nil, .HEADER_IS_NOT_JSON_IN_EVAL_UPDATE
		if len(header.data.(types.object_json_t).value) > 0 {
			header_data = object.to_json_string(header) or_return
		}
	}
	if body.type == .STRING do body_data = body.data.(string)
	else if body.type == .JSON do body_data = object.to_json_string(body) or_return
	else do return nil, .BODY_NEEDS_TO_BE_STRING_OR_JSON_IN_EVAL_UPDATE
	ret_body, ret_head := http.patch(url.data.(string), header_data, body_data) or_return
	ret_obj = object.create_http_response(ret_body, ret_head) or_return
	return
}
