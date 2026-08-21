package object

import "../types"
import "core:strconv"
import "core:strings"

create_http_head :: proc(head_str: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	head_obj := create_json("{}") or_return
	line_iterator := head_str
	status_line, _ := strings.split_lines_iterator(&line_iterator)
	status_parts := strings.fields(status_line)
	defer delete(status_parts)
	response_code_str: string
	if len(status_parts) >= 2 {
		response_code_str = status_parts[1]
	}
	head_ref := &head_obj.data.(types.object_json_t)

	response_int, _ := strconv.parse_int(response_code_str)
	response_item := create_int(response_int) or_return
	response_item.name = "code"
	append(&head_ref.value, response_item)
	for line in strings.split_lines_iterator(&line_iterator) {
		trimmed_line := strings.trim_space(line)
		if len(trimmed_line) == 0 do continue
		key_raw, found, val_raw := strings.partition(trimmed_line, ":")
		if found == {} do continue
		clean_key, _ := strings.replace_all(strings.trim_space(key_raw), "-", "_")
		clean_val := strings.trim_space(val_raw)
		item_obj := create_string(clean_val) or_return
		item_obj.name = clean_key
		append(&head_ref.value, item_obj)
	}
	head_obj.name = "head"
	return head_obj, .OK
}

create_http_body :: proc(body_str: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	body_obj, body_obj_err := create_json(body_str)
	if body_obj_err == .FAILED_TO_PARSE_JSON_IN_CREATE_JSON {
		return create_string(body_str)
	}
	body_obj.name = "body"
	return body_obj, body_obj_err
}

create_http_response :: proc(
	body_str: string,
	head_str: string,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	response := create_json("{}") or_return
	response_ref := &response.data.(types.object_json_t)
	if head_str != {} && head_str != "" {
		body := create_http_body(body_str) or_return
		body.parent = response
		append(&response_ref.value, body)
	}
	if head_str != {} && head_str != "" {
		head := create_http_head(head_str) or_return
		head.parent = response
		append(&response_ref.value, head)
	}
	return response, .OK
}
