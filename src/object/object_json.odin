package object

import "../sys"
import "../types"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

json_value_to_object :: proc(
	val: json.Value,
	key_name: string = "",
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	switch v in val {
	case json.Null:
		ret_obj, code = create_null()

	case json.Boolean:
		ret_obj, code = create_bool(v)

	case json.Integer:
		ret_obj, code = create_int(int(v))

	case json.Float:
		ret_obj, code = create_float(f32(v))

	case json.String:
		ret_obj, code = create_string(strings.clone_from(v))

	case json.Array:
		ret_obj = create_array() or_return
		arr := &ret_obj.data.(types.object_array_t)
		for item in v {
			child, child_code := json_value_to_object(item)
			if child_code != .OK {
				remove(ret_obj)
				return nil, child_code
			}
			child.parent = ret_obj
			append(&arr.value, child)
			arr.count += 1
		}
	case json.Object:
		ret_obj = new(types.object_t)
		if ret_obj == nil do return nil, .OBJECT_IS_NIL_IN_JSON_VALUE_TO_OBJECT
		ret_obj.is_marked = false
		ret_obj.type = .JSON
		ret_obj.ref_count = 1
		json_data := types.object_json_t{}
		for key, child_val in v {
			child, child_code := json_value_to_object(child_val, key)
			if child_code != .OK {
				remove(ret_obj)
				return nil, child_code
			}
			child.parent = ret_obj
			append(&json_data.value, child)
		}
		ret_obj.data = json_data
	}
	if len(key_name) > 0 {
		ret_obj.name = strings.clone_from(key_name)
	}
	return
}

from_json_string :: proc(json_str: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	doc, err := json.parse_string(json_str)
	if err != .None {
		return nil, .OBJECT_IS_NIL_IN_FROM_JSON_STRING
	}
	defer json.destroy_value(doc)
	ret_obj = json_value_to_object(doc, "") or_return
	return
}

json_get :: proc(
	obj: ^types.object_t,
	name: string,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if obj == nil do return nil, .OBJECT_IS_NIL_IN_JSON_GET
	if obj.type != .JSON do return nil, .OBJECT_IS_NOT_JSON_OBJECT_IN_JSON_GET
	target := obj.data.(types.object_json_t)
	for i := 0; i < len(target.value); i += 1 {
		if target.value[i].name == name {
			return target.value[i], .OK
		}
	}
	ret_obj = create_json("{}") or_return
	ret_obj.name = strings.clone_from(name)
	ret_obj.parent = obj
	if json_obj := &obj.data.(types.object_json_t); json_obj != nil {
		append(&json_obj.value, ret_obj)
	}
	return
}

to_json_string :: proc(obj: ^types.object_t) -> (ret_str: string, code: types.exit_codes) {
	if obj == nil do return "", .OBJECT_IS_NIL_IN_TO_JSON_STRING
	sb := strings.builder_make(context.allocator)
	err := serialize_value(&sb, obj)
	if sys.is_error(err) {
		strings.builder_destroy(&sb)
		return "", err
	}
	ret_str = strings.to_string(sb)
	return
}

serialize_value :: proc(sb: ^strings.Builder, obj: ^types.object_t) -> (code: types.exit_codes) {
	if obj == nil {
		strings.write_string(sb, "null")
		return
	}
	#partial switch obj.type {
	case .NULL:
		strings.write_string(sb, "null")
	case .BOOL:
		strings.write_string(sb, obj.data.(bool) ? "true" : "false")
	case .INT:
		fmt.sbprintf(sb, "%d", obj.data.(int))
	case .FLOAT:
		fmt.sbprintf(sb, "%g", obj.data.(f32))
	case .STRING:
		strings.write_byte(sb, '"')
		write_escaped_string(sb, obj.data.(string))
		strings.write_byte(sb, '"')
	case .ARRAY:
		arr := obj.data.(types.object_array_t)
		strings.write_byte(sb, '[')
		for item, i in arr.value {
			if i > 0 do strings.write_string(sb, ", ")
			serialize_value(sb, item) or_return
		}
		strings.write_byte(sb, ']')
	case .JSON:
		json_obj := obj.data.(types.object_json_t)
		strings.write_byte(sb, '{')
		for item, i in json_obj.value {
			if i > 0 do strings.write_string(sb, ", ")
			// Write key
			strings.write_byte(sb, '"')
			write_escaped_string(sb, item.name)
			strings.write_string(sb, "\": ")
			// Write value node
			serialize_value(sb, item) or_return
		}
		strings.write_byte(sb, '}')
	case .VECTOR:
		vec := obj.data.(types.object_vector_t)
		strings.write_byte(sb, '[')
		serialize_value(sb, vec.x) or_return
		strings.write_string(sb, ", ")
		serialize_value(sb, vec.y) or_return
		strings.write_string(sb, ", ")
		serialize_value(sb, vec.z) or_return
		strings.write_byte(sb, ']')
	case:
		strings.write_string(sb, "null")
	}
	return
}

write_escaped_string :: proc(sb: ^strings.Builder, str: string) {
	for r in str {
		switch r {
		case '"':
			strings.write_string(sb, "\\\"")
		case '\\':
			strings.write_string(sb, "\\\\")
		case '\n':
			strings.write_string(sb, "\\n")
		case '\r':
			strings.write_string(sb, "\\r")
		case '\t':
			strings.write_string(sb, "\\t")
		case:
			strings.write_rune(sb, r)
		}
	}
}

json_write_file :: proc(obj: ^types.object_t) -> (code: types.exit_codes) {
	obj := obj
	if obj == nil do return .OBJECT_IS_NIL_IN_JSON_WRITE_FILE
	for obj.parent != nil do obj = obj.parent
	if obj.data.(types.object_json_t).file != {} {
		text := to_json_string(obj) or_return
		write_err := os.write_entire_file(obj.data.(types.object_json_t).file.name, text)
		if write_err != os.General_Error.None do return .ERROR_WRITING_FILE_IN_JSON_WRITE_FILE
	}
	return
}

create_json_from_file :: proc(file: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	text_data, err := os.read_entire_file(file, context.allocator)
	if err != os.General_Error.None {
		return nil, .FAILED_TO_READ_FILE_IN_CREATE_JSON_FROM_FILE
	}
	defer delete(text_data)
	text := string(text_data)
	ret_obj = create_json(text) or_return
	return
}
