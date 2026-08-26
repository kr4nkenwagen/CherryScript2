package evaluator

import "../http"
import "../object"
import "../types"

eval_connect :: proc(obj: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	body_ret: string
	ret_head: string
	if obj.type == .STRING {
		body_ret, ret_head = http.connect(obj.data.(string)) or_return
	} else if obj.type == .JSON {
		url := object.json_get(obj, "url") or_return
		header := object.json_get(obj, "head") or_return
		if len(header.data.(types.object_json_t).value) > 0 {
			header_data := object.to_json_string(header) or_return
			body_ret, ret_head = http.connect(url.data.(string), header_data) or_return
		} else {
			body_ret, ret_head = http.connect(url.data.(string)) or_return
		}
	} else {
		return nil, .UNSUPPORTED_OBJECT_TYPE_IN_EVAL_CONNECT
	}
	ret_obj = object.create_http_response(body_ret, ret_head) or_return
	return
}
