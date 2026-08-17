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
	^types.object_t,
	types.exit_codes,
) {
	obj: ^types.object_t
	code: types.exit_codes

	switch v in val {
	case json.Null:
		obj, code = create_null()

	case json.Boolean:
		obj, code = create_bool(v)

	case json.Integer:
		obj, code = create_int(int(v))

	case json.Float:
		obj, code = create_float(f32(v))

	case json.String:
		obj, code = create_string(strings.clone_from(v))

	case json.Array:
		obj, code = create_array()
		if code != .OK do return nil, code

		arr := &obj.data.(types.object_array_t)
		for item in v {
			child, child_code := json_value_to_object(item)
			if child_code != .OK {
				remove(obj)
				return nil, child_code
			}
			child.parent = obj
			append(&arr.value, child)
			arr.count += 1
		}
	case json.Object:
		obj = new(types.object_t)
		if obj == nil do return nil, .OBJECT_IS_NIL
		obj.is_marked = false
		obj.type = .JSON
		obj.ref_count = 1
		json_data := types.object_json_t{}
		for key, child_val in v {
			child, child_code := json_value_to_object(child_val, key)
			if child_code != .OK {
				remove(obj)
				return nil, child_code
			}
			child.parent = obj
			append(&json_data.value, child)
		}
		obj.data = json_data
		code = .OK
	}

	if code != .OK do return nil, code

	if len(key_name) > 0 {
		obj.name = strings.clone_from(key_name)
	}
	return obj, .OK
}

from_json_string :: proc(json_str: string) -> (^types.object_t, types.exit_codes) {
	doc, err := json.parse_string(json_str)
	if err != .None {
		return nil, .OBJECT_IS_NIL
	}
	defer json.destroy_value(doc)

	return json_value_to_object(doc, "")
}

json_get :: proc(obj: ^types.object_t, name: string) -> (^types.object_t, types.exit_codes) {
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	if obj.type != .JSON {
		return nil, .UNEXPECTED_BEHAVIOUR
	}
	target := obj.data.(types.object_json_t)
	for i := 0; i < len(target.value); i += 1 {
		if target.value[i].name == name {
			return target.value[i], .OK
		}
	}
	null_obj, null_obj_err := create_json("{}")
	if sys.is_error(null_obj_err) {
		return nil, null_obj_err
	}
	null_obj.name = strings.clone_from(name)
	null_obj.parent = obj
	if json_obj := &obj.data.(types.object_json_t); json_obj != nil {
		append(&json_obj.value, null_obj)
	}
	return null_obj, .OK
}

to_json_string :: proc(
	obj: ^types.object_t,
	allocator := context.allocator,
) -> (
	string,
	types.exit_codes,
) {
	if obj == nil {
		return "", .OBJECT_IS_NIL
	}
	sb := strings.builder_make(allocator)
	err := serialize_value(&sb, obj)
	if sys.is_error(err) {
		strings.builder_destroy(&sb)
		return "", err
	}
	return strings.to_string(sb), .OK
}

serialize_value :: proc(sb: ^strings.Builder, obj: ^types.object_t) -> types.exit_codes {
	if obj == nil {
		strings.write_string(sb, "null")
		return .OK
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
			code := serialize_value(sb, item)
			if code != .OK do return code
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
			code := serialize_value(sb, item)
			if code != .OK do return code
		}
		strings.write_byte(sb, '}')
	case .VECTOR:
		vec := obj.data.(types.object_vector_t)
		strings.write_byte(sb, '[')
		if code := serialize_value(sb, vec.x); code != .OK do return code
		strings.write_string(sb, ", ")
		if code := serialize_value(sb, vec.y); code != .OK do return code
		strings.write_string(sb, ", ")
		if code := serialize_value(sb, vec.z); code != .OK do return code
		strings.write_byte(sb, ']')
	case:
		strings.write_string(sb, "null")
	}
	return .OK
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

json_write_file :: proc(obj: ^types.object_t) -> types.exit_codes {
	obj := obj
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	for obj.parent != nil {
		obj = obj.parent
	}
	if obj.data.(types.object_json_t).file != {} {
		text, text_err := to_json_string(obj)
		if sys.is_error(text_err) {
			return text_err
		}
		write_err := os.write_entire_file(obj.data.(types.object_json_t).file.name, text)
		if write_err != os.General_Error.None {
			return .ERROR
		}
	}
	return .OK
}

create_json_from_file :: proc(file: string) -> (^types.object_t, types.exit_codes) {
	text_data, err := os.read_entire_file(file, context.allocator)
	if err != os.General_Error.None {
		return nil, .FAILED_TO_READ_FILE
	}
	defer delete(text_data)
	text := string(text_data)
	return create_json(text)
}
