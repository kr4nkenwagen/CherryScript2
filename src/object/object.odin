package object

import "../types"

create_int :: proc(value: int) -> (^types.object_t, types.exit_codes) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.INT
	obj.data = value
	obj.ref_count = 1
	return obj, .OK
}

create_bool :: proc(value: bool) -> (^types.object_t, types.exit_codes) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.BOOL
	obj.data = value
	obj.ref_count = 1
	return obj, .OK
}

create_float :: proc(value: f32) -> (^types.object_t, types.exit_codes) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.FLOAT
	obj.data = value
	obj.ref_count = 1
	return obj, .OK
}

create_string :: proc(value: string) -> (^types.object_t, types.exit_codes) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.STRING
	obj.data = value
	obj.ref_count = 1
	return obj, .OK
}

create_array :: proc() -> (^types.object_t, types.exit_codes) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.ARRAY
	obj.ref_count = 1
	obj.data = types.object_array_t {
		count = 0,
	}
	return obj, .OK
}

create_vector :: proc(
	x: ^types.object_t,
	y: ^types.object_t,
	z: ^types.object_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.VECTOR
	obj.data = types.object_vector_t {
		x = x,
		y = y,
		z = z,
	}
	obj.ref_count = 1
	return obj, .OK
}

create_funct :: proc(synt: ^types.syntax_t) -> (^types.object_t, types.exit_codes) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj := new(types.object_t)
	if obj == nil {
		return nil, .MEMORY_ALLOCATION_FAILED
	}
	obj.type = .FUNCTION
	obj.data = synt
	return obj, .OK
}

create_null :: proc() -> (^types.object_t, types.exit_codes) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj.is_marked = false
	obj.type = types.object_type_t.NULL
	obj.ref_count = 1
	return obj, .OK
}

set_null :: proc(obj: ^types.object_t) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	obj.type = types.object_type_t.NULL
	return .OK
}

length :: proc(obj: ^types.object_t) -> (int, types.exit_codes) {
	if obj == nil {
		return -1, .OBJECT_IS_NIL
	}
	switch (obj.type) {
	case .INT:
		fallthrough
	case .FLOAT:
		return 1, .OK
	case .STRING:
		return len(obj.data.(string)), .OK
	case .ARRAY:
		return obj.data.(types.object_array_t).count, .OK
	case .VECTOR:
	case .NULL:
	case .BOOL:
	case .FUNCTION:
	}
	return -1, .OBJECT_IS_UNKNOWN_TYPE
}

ref_dec :: proc(obj: ^types.object_t) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	obj.ref_count -= 1
	if obj.ref_count == 0 {
		free(obj)
	}
	return .OK
}

ref_inc :: proc(obj: ^types.object_t) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	obj.ref_count += 1
	return .OK
}

remove :: proc(obj: ^types.object_t) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
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
	case .FUNCTION:
	case .ARRAY:
		for i := 1; i < obj.data.(types.object_array_t).count; i += 1 {
			free(&obj.data.(types.object_array_t).value[i])
		}
	case .VECTOR:
		free(obj.data.(types.object_vector_t).x)
		free(obj.data.(types.object_vector_t).y)
		free(obj.data.(types.object_vector_t).z)
	}
	free(obj)
	return .OK
}

copy :: proc(src: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if src == nil {
		return nil, .OBJECT_IS_NIL
	}
	obj, err := new(types.object_t)
	if err != .None {
		return nil, .MEMORY_ALLOCATION_FAILED
	}
	obj^ = src^
	return obj, .OK
}
