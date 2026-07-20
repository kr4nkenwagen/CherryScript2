package object

import "../object"
import "../sys"
import "../types"

add :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	if a.type == .INT {
		if b.type == .FLOAT {
			return object.create_int(int(f64(a.data.(int)) + f64(b.data.(f32))))
		} else if b.type == .INT {
			return object.create_int(a.data.(int) + b.data.(int))
		}
		if b.type == .STRING {
			num, err := int_to_number(int(a.data.(int)))
			if sys.is_error(err) do return nil, err
			joined, concat_err := join_string(num, b.data.(string))
			if sys.is_error(concat_err) do return nil, concat_err
			return object.create_string(joined)
		}
	}
	if a.type == .FLOAT {
		if b.type == .INT {
			return object.create_float(f32(f64(a.data.(f32)) + f64(b.data.(int))))
		} else if b.type == .FLOAT {
			return object.create_float(a.data.(f32) + b.data.(f32))
		}
	}
	if a.type == .STRING {
		if b.type == .STRING {
			joined, concat_err := join_string(a.data.(string), b.data.(string))
			if sys.is_error(concat_err) do return nil, concat_err
			return object.create_string(joined)
		} else if b.type == .INT {
			num, err := int_to_number(int(b.data.(int)))
			if sys.is_error(err) do return nil, err
			joined, concat_err := join_string(a.data.(string), num)
			if sys.is_error(concat_err) do return nil, concat_err
			return object.create_string(joined)
		}
	}
	return nil, .TYPE_MISMATCH
}

subtract :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	if a.type == .INT {
		if b.type == .FLOAT {
			return object.create_int(int(f64(a.data.(int)) - f64(b.data.(f32))))
		} else if b.type == .INT {
			return object.create_int(a.data.(int) - b.data.(int))
		}
	}
	if a.type == .FLOAT {
		if b.type == .INT {
			return object.create_float(f32(f64(a.data.(f32)) - f64(b.data.(int))))
		} else if b.type == .FLOAT {
			return object.create_float(a.data.(f32) - b.data.(f32))
		}
	}
	if a.type == .STRING {
		if b.type == .STRING {
			return strip_instances_from_string(a, b)
		} else if b.type == .INT {
			return shorten_string(a, b)
		}
	}
	return nil, .TYPE_MISMATCH
}

multiply :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	if a.type == .INT {
		if b.type == .FLOAT {
			return object.create_int(int(f64(a.data.(int)) * f64(b.data.(f32))))
		} else if b.type == .INT {
			return object.create_int(a.data.(int) * b.data.(int))
		}
	}
	if a.type == .FLOAT {
		if b.type == .INT {
			return object.create_float(f32(f64(a.data.(f32)) * f64(b.data.(int))))
		} else if b.type == .FLOAT {
			return object.create_float(a.data.(f32) * b.data.(f32))
		}
	}
	if a.type == .STRING {
		if b.type == .INT {
			return multiply_string(a, b)
		}
	}
	return nil, .TYPE_MISMATCH
}

divide :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	if a.type == .INT {
		if a.data.(int) == 0 do return nil, .DIVISION_BY_ZERO
		if b.type == .FLOAT {
			if b.data.(f32) == 0 do return nil, .DIVISION_BY_ZERO
			return object.create_int(int(f64(a.data.(int)) / f64(b.data.(f32))))
		} else if b.type == .INT {
			if b.data.(int) == 0 do return nil, .DIVISION_BY_ZERO
			return object.create_int(a.data.(int) / b.data.(int))
		}
	}
	if a.type == .FLOAT {
		if a.data.(f32) == 0 do return nil, .DIVISION_BY_ZERO
		if b.type == .INT {
			if b.data.(int) == 0 do return nil, .DIVISION_BY_ZERO
			return object.create_float(f32(f64(a.data.(f32)) / f64(b.data.(int))))
		} else if b.type == .FLOAT {
			if b.data.(f32) == 0 do return nil, .DIVISION_BY_ZERO
			return object.create_float(a.data.(f32) / b.data.(f32))
		}
	}
	if a.type == .STRING {
		if b.type == .INT {
			return divide_string(a, b)
		}
	}
	return nil, .TYPE_MISMATCH
}

modulus :: proc(a, b: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL
	}
	if a.type == .INT {
		if b.type == .INT {
			if b.data.(int) == 0 do return nil, .DIVISION_BY_ZERO
			return object.create_int(a.data.(int) % b.data.(int))
		}
	}
	if a.type == .STRING {
		if b.type == .INT {
			return modulus_string(a, b)
		}
	}
	return nil, .TYPE_MISMATCH
}

assign :: proc(target, source: ^types.object_t) -> types.exit_codes {
	if target == nil || source == nil {
		return .OBJECT_IS_NIL
	}
	if target.is_const {
		return .CANNOT_ASSIGN_TO_CONSTANT
	}
	target.data = source.data
	target.type = source.type
	return .OK
}
