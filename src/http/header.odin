package http

import "core:encoding/json"
import "core:fmt"
import "core:strings"
import "vendor:curl"

parse_header_list :: proc(json_headers: string) -> ^curl.slist {
	if len(json_headers) == 0 do return nil
	val, err := json.parse_string(json_headers, parse_integers = true)
	if err != .None do return nil
	defer json.destroy_value(val)
	obj, ok := val.(json.Object)
	if !ok do return nil
	header_list: ^curl.slist = nil
	for key, v in obj {
		value_str: string
		#partial switch variant in v {
		case json.String:
			value_str = variant
		case json.Integer:
			value_str = fmt.tprintf("%d", variant)
		case json.Float:
			if variant == f64(i64(variant)) {
				value_str = fmt.tprintf("%d", i64(variant))
			} else {
				value_str = fmt.tprintf("%f", variant)
			}
		case json.Boolean:
			value_str = fmt.tprintf("%t", variant)
		case:
			continue
		}
		new_key, _ := strings.replace_all(key, "_", "-", context.temp_allocator)
		header_fmt := fmt.tprintf("%s: %s", new_key, value_str)
		c_hdr := strings.clone_to_cstring(header_fmt, context.temp_allocator)
		header_list = curl.slist_append(header_list, c_hdr)
	}
	return header_list
}
