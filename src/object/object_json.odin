package object

import "../sys"
import "../types"
import "core:encoding/json"
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
	if json_obj := &obj.data.(types.object_json_t); json_obj != nil {
		append(&json_obj.value, null_obj)
	}
	return null_obj, .OK
}
