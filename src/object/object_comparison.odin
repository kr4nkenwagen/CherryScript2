package object

import "../object"
import "../types"

get_numeric_value :: proc(obj: ^types.object_t) -> (f64, bool) {
	if obj == nil do return 0, false
	#partial switch obj.type {
	case .INT:
		return f64(obj.data.(int)), true
	case .FLOAT:
		return f64(obj.data.(f32)), true
	case .BOOL:
		return obj.data.(bool) ? 1 : 0, true
	case:
		return 0, false
	}
}

equals :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
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
	return nil, .TYPE_MISMATCH
}

not_equals :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
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
	return nil, .TYPE_MISMATCH
}

greater_equals :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a >= val_b)
	}
	if a.type == .NULL && b.type == .NULL {
		return object.create_bool(true)
	}
	return nil, .TYPE_MISMATCH
}

greater :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a > val_b)
	}
	return nil, .TYPE_MISMATCH
}

less :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a < val_b)
	}
	return nil, .TYPE_MISMATCH
}

less_equals :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	val_a, ok_a := get_numeric_value(a)
	val_b, ok_b := get_numeric_value(b)
	if ok_a && ok_b {
		return object.create_bool(val_a <= val_b)
	}
	return nil, .TYPE_MISMATCH
}
