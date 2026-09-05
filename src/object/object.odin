package object

import "../types"
import "core:encoding/json"
import "core:unicode/utf8"

create_int :: proc(value: int) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .OBJECT_IS_NIL_IN_CREATE_INT
	}
	ret_obj.is_marked = false
	ret_obj.type = .INT
	ret_obj.data = value
	return
}

create_bool :: proc(value: bool) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .OBJECT_IS_NIL_IN_CREATE_BOOL
	}
	ret_obj.is_marked = false
	ret_obj.type = .BOOL
	ret_obj.data = value
	return
}

create_float :: proc(value: f32) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .OBJECT_IS_NIL_CREATE_FLOAT
	}
	ret_obj.is_marked = false
	ret_obj.type = .FLOAT
	ret_obj.data = value
	return
}

create_string :: proc(value: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .OBJECT_IS_NIL_IN_CREATE_STRING
	}
	ret_obj.is_marked = false
	ret_obj.type = .STRING
	ret_obj.data = value
	return
}

create_array :: proc() -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .OBJECT_IS_NIL_IN_CREATE_ARRAY
	}
	ret_obj.is_marked = false
	ret_obj.type = .ARRAY
	ret_obj.data = types.object_array_t {
		count = 0,
	}
	return
}

create_funct :: proc(synt: ^types.syntax_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL_IN_CREATE_FUNCT
	}
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .MEMORY_ALLOCATION_FAILED_IN_CREATE_FUNCT
	}
	ret_obj.type = .FUNCTION
	ret_obj.data = synt
	return
}

create_file :: proc(file: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .MEMORY_ALLOCATION_FAILED_IN_CREATE_FILE
	}
	ret_obj.type = .FILE
	ret_obj.data = types.object_file_t {
		name = file,
	}
	return
}

create_json :: proc(json_str: string) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	json_str := len(json_str) == 0 ? "{}" : json_str
	doc, err := json.parse_string(json_str)
	if err != .None {
		return nil, .FAILED_TO_PARSE_JSON_IN_CREATE_JSON
	}
	defer json.destroy_value(doc)
	return json_value_to_object(doc, "")
}

create_null :: proc() -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .MEMORY_ALLOCATION_FAILED_IN_CREATE_NIL
	}
	ret_obj.is_marked = false
	ret_obj.type = types.object_type_t.NULL
	return
}

set_null :: proc(obj: ^types.object_t) -> (code: types.exit_codes) {
	if obj == nil {
		return .OBJECT_IS_NIL_IN_SET_NULL
	}
	obj.type = types.object_type_t.NULL
	return
}

length :: proc(obj: ^types.object_t) -> (ret_int: int, code: types.exit_codes) {
	if obj == nil {
		return -1, .OBJECT_IS_NIL_IN_LENGTH
	}
	switch (obj.type) {
	case .INT:
		return int_len(obj.data.(int))
	case .FLOAT:
		return float_len(obj.data.(f32))
	case .STRING:
		return utf8.rune_count_in_string(obj.data.(string)), .OK
	case .ARRAY:
		return obj.data.(types.object_array_t).count, .OK
	case .JSON:
		return len(obj.data.(types.object_json_t).value), .OK
	case .FILE:
		return file_length(obj.data.(types.object_file_t).name)
	case .NULL, .BOOL, .FUNCTION:
	}
	return -1, .OBJECT_IS_UNKNOWN_TYPE_IN_LENGTH
}

remove :: proc(obj: ^types.object_t) -> (code: types.exit_codes) {
	if obj == nil {
		return .OBJECT_IS_NIL_IN_OBJECT_REMOVE
	}
	switch (obj.type) {
	case .INT:
		fallthrough
	case .FLOAT:
		fallthrough
	case .STRING:
		fallthrough
	case .NULL:
		fallthrough
	case .BOOL:
		fallthrough
	case .FILE:
		fallthrough
	case .FUNCTION:
	case .ARRAY:
		for i := 1; i < obj.data.(types.object_array_t).count; i += 1 {
			free(&obj.data.(types.object_array_t).value[i])
		}
	case .JSON:
		for item in obj.data.(types.object_json_t).value {
			remove(item)
		}
		delete(obj.data.(types.object_json_t).value)
	}
	free(obj)
	return
}

copy :: proc(src: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_COPY
	}
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .MEMORY_ALLOCATION_FAILED_IN_OBJECT_COPY
	}
	ret_obj^ = src^
	return
}

copy_deep :: proc(src: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_COPY
	}
	ret_obj = new(types.object_t)
	if ret_obj == nil {
		return nil, .MEMORY_ALLOCATION_FAILED_IN_OBJECT_COPY
	}
	ret_obj.type = src.type
	ret_obj.name = src.name
	#partial switch src.type {
	case .ARRAY:
		arr := src.data.(types.object_array_t)
		new_arr := types.object_array_t {count = arr.count}
		for item in arr.value {
			child := copy_deep(item) or_return
			if item.parent != nil do child.parent = ret_obj
			append(&new_arr.value, child)
		}
		ret_obj.data = new_arr
	case .JSON:
		json_obj := src.data.(types.object_json_t)
		new_json := types.object_json_t {file = json_obj.file}
		for item in json_obj.value {
			child := copy_deep(item) or_return
			if item.parent != nil do child.parent = ret_obj
			append(&new_json.value, child)
		}
		ret_obj.data = new_json
	case:
		ret_obj.data = src.data
	}
	return
}

copy_array_data :: proc(src: types.object_array_t, container: ^types.object_t) -> (data: types.object_array_t, code: types.exit_codes) {
	data = types.object_array_t {count = src.count}
	for item in src.value {
		child := copy_deep(item) or_return
		if item.parent != nil do child.parent = container
		append(&data.value, child)
	}
	return
}

copy_json_data :: proc(src: types.object_json_t, container: ^types.object_t) -> (data: types.object_json_t, code: types.exit_codes) {
	data = types.object_json_t {file = src.file}
	for item in src.value {
		child := copy_deep(item) or_return
		if item.parent != nil do child.parent = container
		append(&data.value, child)
	}
	return
}
