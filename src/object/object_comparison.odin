package object

import "../object"
import "../types"

get_numeric_value :: proc(obj: ^types.object_t) -> (ret_f64: f64, ret_bl: bool) {
	if obj == nil do return 0, false
	#partial switch obj.type {
	case .INT:
		return f64(obj.data.(int)), true
	case .FLOAT:
		return f64(obj.data.(f32)), true
	case .BOOL:
		return obj.data.(bool) ? 1 : 0, true
	case:
		return
	}
}

equals :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_ON_OBJECT_EQUAL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a == val_b)
	}
	if a.type == .STRING && b.type == .STRING {
		return object.create_bool(a.data.(string) == b.data.(string))
	}
	if a.type == .NULL && b.type == .NULL {
		return object.create_bool(true)
	}
	code = .TYPE_MISMATCH_IN_OBJECT_EQUAL
	return
}

not_equals :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_NOT_EQUAL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a != val_b)
	}
	if a.type == .STRING && b.type == .STRING {
		return object.create_bool(a.data.(string) != b.data.(string))
	}
	if a.type == .NULL && b.type == .NULL {
		return object.create_bool(false)
	}
	code = .TYPE_MISMATCH_IN_OBJECT_NOT_EQUAL
	return
}

greater_equals :: proc(
	a, b: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_GREATER_EQUAL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a >= val_b)
	}
	if a.type == .NULL && b.type == .NULL {
		return object.create_bool(true)
	}
	code = .TYPE_MISMATCH_IN_OBJECT_GREATER_EQUAL
	return
}

greater :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_GREATER
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a > val_b)
	}
	code = .TYPE_MISMATCH_IN_OBJECT_GREATER
	return
}

less :: proc(a, b: ^types.object_t) -> (ret_obk: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_LESS
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a < val_b)
	}
	code = .TYPE_MISMATCH_IN_OBJECT_LESS
	return
}

less_equals :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_LESS_EQUAL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a <= val_b)
	}
	code = .TYPE_MISMATCH_IN_OBJECT_LESS_EQUAL
	return
}
