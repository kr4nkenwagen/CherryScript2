package object

import "../object"
import "../types"

add :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIl_in_OBJECT_ADD
	}
	if a.type == .INT {
		if b.type == .FLOAT {
			return object.create_int(int(f64(a.data.(int)) + f64(b.data.(f32))))
		} else if b.type == .INT {
			return object.create_int(a.data.(int) + b.data.(int))
		}
		if b.type == .STRING {

			return join_string(a, b)
		}
	}
	if a.type == .FLOAT {
		if b.type == .INT {
			return object.create_float(f32(f64(a.data.(f32)) + f64(b.data.(int))))
		} else if b.type == .FLOAT {
			return object.create_float(a.data.(f32) + b.data.(f32))
		} else if b.type == .STRING {

			return join_string(a, b)
		}
	}
	if a.type == .STRING {
		if b.type == .STRING {
			return join_string(a, b)
		} else if b.type == .INT || b.type == .FLOAT {
			return object.lengthen_string(a, b)
		}
	}
	if a.type == .ARRAY {
		if b.type == .ARRAY {
			c := copy(a) or_return
			for i in 0 ..< b.data.(types.object_array_t).count {
				array_set(
					c,
					c.data.(types.object_array_t).count,
					b.data.(types.object_array_t).value[i],
				)
			}
			return c, .OK
		}
	}
	code = .TYPE_MISMATCH_IN_OBJECT_ADD
	return
}

subtract :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_SUBTRACT
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
	code = .TYPE_MISMATCH_IN_OBJECT_SUBTRACT
	return
}

multiply :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_MULTIPLY
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
	code = .TYPE_MISMATCH_IN_OBJECT_MULTUPLY
	return
}

divide :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_DIVIDE
	}
	if a.type == .INT {
		if a.data.(int) == 0 do return nil, .DIVISION_BY_ZERO_A_INT_IN_OBJECT_DIVIDE
		if b.type == .FLOAT {
			if b.data.(f32) == 0 do return nil, .DIVISION_BY_ZERO_A_INT_B_FLOAT_IN_OBJECT_DIVIDE
			return object.create_int(int(f64(a.data.(int)) / f64(b.data.(f32))))
		} else if b.type == .INT {
			if b.data.(int) == 0 do return nil, .DIVISION_BY_ZERO_A_INT_B_INT_IN_OBJECT_DIVIDE
			return object.create_int(a.data.(int) / b.data.(int))
		}
	}
	if a.type == .FLOAT {
		if a.data.(f32) == 0 do return nil, .DIVISION_BY_ZERO_A_FLOAT_IN_OBJECT_DIVIDE
		if b.type == .INT {
			if b.data.(int) == 0 do return nil, .DIVISION_BY_ZERO_A_FLOAT_B_INT_IN_OBJECT_DIVIDE
			return object.create_float(f32(f64(a.data.(f32)) / f64(b.data.(int))))
		} else if b.type == .FLOAT {
			if b.data.(f32) == 0 do return nil, .DIVISION_BY_ZERO_A_FLOAT_B_FLOAT_IN_OBJECT_DIVIDE
			return object.create_float(a.data.(f32) / b.data.(f32))
		}
	}
	if a.type == .STRING {
		if b.type == .INT {
			return divide_string(a, b)
		}
	}
	code = .TYPE_MISMATCH_IN_OBJECT_DIVIDE
	return
}

modulus :: proc(a, b: ^types.object_t) -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	if a == nil || b == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_MODULUS
	}
	if a.type == .INT {
		if b.type == .INT {
			if b.data.(int) == 0 do return nil, .DIVISION_BY_ZERO_A_INT_B_INT_IN_OBJECT_MODULUS
			return object.create_int(a.data.(int) % b.data.(int))
		}
	}
	if a.type == .STRING {
		if b.type == .INT {
			return modulus_string(a, b)
		}
	}
	code = .TYPE_MISMATCH_IN_OBJECT_MODULUS
	return
}


assign :: proc(target, source: ^types.object_t) -> (code: types.exit_codes) {
	if target == nil || source == nil {
		return .OBJECT_IS_NIL_IN_OBJECT_ASSIGN
	}
	if target.is_const {
		return .CANNOT_ASSIGN_TO_CONSTANT_IN_OBJECT_ASSIGN
	}
	target.type = source.type
	#partial switch source.type {
	case .ARRAY:
		target.data = copy_array_data(source.data.(types.object_array_t), target) or_return
	case .JSON:
		target.data = copy_json_data(source.data.(types.object_json_t), target) or_return
	case:
		target.data = source.data
	}
	if target.parent != nil {
		json_write_file(target)
	}
	return
}
