package object

import "../types"

create_int :: proc(value: int) -> (^types.object_t, bool) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.INT
	obj.data = value
	obj.ref_count = 1
	return obj, false
}

create_bool :: proc(value: bool) -> (^types.object_t, bool) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.BOOL
	obj.data = value
	obj.ref_count = 1
	return obj, false
}

create_float :: proc(value: f32) -> (^types.object_t, bool) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.FLOAT
	obj.data = value
	obj.ref_count = 1
	return obj, false
}

create_string :: proc(value: string) -> (^types.object_t, bool) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.STRING
	obj.data = value
	obj.ref_count = 1
	return obj, false
}

create_array :: proc() -> (^types.object_t, bool) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.ARRAY
	obj.ref_count = 1
	obj.data = types.object_array_t {
		count = 0,
	}
	return obj, false
}

create_vector :: proc(
	x: ^types.object_t,
	y: ^types.object_t,
	z: ^types.object_t,
) -> (
	^types.object_t,
	bool,
) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.VECTOR
	obj.data = types.object_vector_t {
		x = x,
		y = y,
		z = z,
	}
	obj.ref_count = 1
	return obj, false
}

//TODO: Create procedure for function objects

create_null :: proc() -> (^types.object_t, bool) {
	obj := new(types.object_t)
	if obj == nil {
		return nil, true
	}
	obj.is_marked = false
	obj.type = types.object_type_t.NULL
	obj.ref_count = 1
	return obj, false
}

set_null :: proc(obj: ^types.object_t) -> bool {
	if obj == nil {
		return true
	}
	obj.type = types.object_type_t.NULL
	return false
}

length :: proc(obj: ^types.object_t) -> (int, bool) {
	if obj == nil {
		return -1, true
	}
	switch (obj.type) {
	case .INT:
		fallthrough
	case .FLOAT:
		return 1, false
	case .STRING:
		return len(obj.data.(string)), false
	case .ARRAY:
		return obj.data.(array_t).count, false
	case .VECTOR:
	case .NULL:
	case .BOOL:
	case .FUNCTION:
	}
	return -1, true
}

ref_dec :: proc(obj: ^types.object_t) -> bool {
	if obj == nil {
		return true
	}
	obj.ref_count -= 1
	if obj.ref_count == 0 {
		free(obj)
	}
	return false
}

ref_inc :: proc(obj: ^types.object_t) -> bool {
	if obj == nil {
		return true
	}
	obj.ref_count += 1
	return false
}

remove :: proc(obj: ^types.object_t) -> bool {
	if obj == nil {
		return true
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
		for i := 1; i < obj.data.(array_t).count; i += 1 {
			free(&obj.data.(array_t).value[i])
		}
	case .VECTOR:
		free(obj.data.(vector_t).x)
		free(obj.data.(vector_t).y)
		free(obj.data.(vector_t).z)
	}
	free(obj)
	return false
}

copy :: proc(src: ^types.object_t) -> (^types.object_t, bool) {
	if src == nil {
		return nil, true
	}
	obj, err := new(types.object_t)
	if err != .None {
		return nil, true
	}
	obj^ = src^
	return obj, false
}
