package evaluator

import "../object"
import "../types"
import "core:math"
import "core:math/rand"

eval_math :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	program.stats.current_syntax = syntax
	type := syntax.value.token.literal
	args: []^types.object_t
	defer delete(args)
	if syntax.value.value != nil {
		args = eval_builtin_function_args(syntax.value, stck, program) or_return
	}
	switch type {
	case "pi":
		return object.create_float(math.PI)
	case "tau":
		return object.create_float(math.TAU)
	case "max":
		return math_max(args)
	case "min":
		return math_min(args)
	case "min_max":
		return math_min_max(args)
	case "clamp":
		return math_min_max(args)
	case "abs":
		return math_abs(args)
	case "sqrt":
		return math_sqrt(args)
	case "sign":
		return math_sign(args)
	case "floor":
		return math_floor(args)
	case "ceil":
		return math_ceil(args)
	case "round":
		return math_round(args)
	case "trunc":
		return math_trunc(args)
	case "random":
		return math_random(args)
	case "random_range":
		return math_random_range(args)
	case "lerp":
		return math_lerp(args)
	case "sin":
		return math_sin(args)
	case "cos":
		return math_cos(args)
	case "tan":
		return math_tan(args)
	case "asin":
		return math_asin(args)
	case "acos":
		return math_acos(args)
	case "atan":
		return math_atan(args)
	case "atan2":
		return math_atan2(args)
	case "log":
		return math_log(args)
	case "hypot":
		return math_hypot(args)
	case:
		code = .UNEXPECTED_MEMBER_IN_EVAL_MATH
	}
	return
}

unpack_f32 :: proc(obj: ^types.object_t) -> (res: f32) {
	#partial switch v in obj.data {
	case int:
		return f32(v)
	case f32:
		return v
	case:
		return 0.0
	}
}


math_max :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_MAX
	val0 := args[0]
	val1 := args[1]
	if (val0.type != .INT && val0.type != .FLOAT) || (val1.type != .INT && val1.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_MAX
	val0_f: f32 = unpack_f32(val0)
	val1_f: f32 = unpack_f32(val1)
	obj = object.create_float(math.max(val0_f, val1_f)) or_return
	return
}

math_min :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_MIN
	val0 := args[0]
	val1 := args[1]
	if (val0.type != .INT && val0.type != .FLOAT) || (val1.type != .INT && val1.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_MIN
	val0_f: f32 = unpack_f32(val0)
	val1_f: f32 = unpack_f32(val1)
	obj = object.create_float(math.min(val0_f, val1_f)) or_return
	return
}

math_min_max :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 3 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_MIN_MAX
	val := args[0]
	min := args[1]
	max := args[2]
	if (val.type != .INT && val.type != .FLOAT) || (max.type != .INT && max.type != .FLOAT) || (min.type != .INT && min.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_MIN_MAX
	val_f: f32 = unpack_f32(val)
	max_f: f32 = unpack_f32(max)
	min_f: f32 = unpack_f32(min)
	if min_f > max_f do return nil, .MIN_IS_GREATER_THAN_MAX_IN_MATH_MIN_MAX
	obj = object.create_float(math.max(math.min(val_f, max_f), min_f)) or_return
	return
}

math_abs :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ABS
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_ABS
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.abs(val_f)) or_return
	return
}

math_sqrt :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_SQRT
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_SQRT
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.sqrt(val_f)) or_return
	return
}

math_sign :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_SIGN
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_SIGN
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.sign(val_f)) or_return
	return
}

math_floor :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_FLOOR
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_FLOOR
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.floor(val_f)) or_return
	return
}

math_ceil :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_CEIL
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_CEIL
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.ceil(val_f)) or_return
	return
}

math_round :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ROUND
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_ROUND
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.round(val_f)) or_return
	return
}

math_trunc :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_TRUNC
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_TRUNC
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.trunc(val_f)) or_return
	return
}

math_random :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 0 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_RANDOM
	obj = object.create_float(rand.float32()) or_return
	return
}

math_random_range :: proc(
	args: []^types.object_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_RANDOM_RANGE
	val0 := args[0]
	val1 := args[1]
	if (val0.type != .INT && val0.type != .FLOAT) || (val1.type != .INT && val1.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_RANDOM_RANGE
	val0_f: f32 = unpack_f32(val0)
	val1_f: f32 = unpack_f32(val1)
	if val0_f > val1_f do return nil, .MIN_IS_GREATER_THAN_MAX_IN_MATH_RANDOM_RANGE
	obj = object.create_float((rand.float32() * (val1_f - val0_f)) + val0_f) or_return
	return
}

math_lerp :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 3 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_LERP
	val := args[0]
	min := args[1]
	max := args[2]
	if (val.type != .INT && val.type != .FLOAT) || (min.type != .INT && min.type != .FLOAT) || (max.type != .INT && max.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_LERP
	val_f: f32 = unpack_f32(val)
	min_f: f32 = unpack_f32(min)
	max_f: f32 = unpack_f32(max)
	obj = object.create_float(math.lerp(min_f, max_f, val_f)) or_return
	return
}

math_sin :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_SIN
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_SIN
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.sin(val_f)) or_return
	return
}

math_cos :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_COS
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_COS
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.cos(val_f)) or_return
	return
}

math_tan :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_TAN
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_TAN
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.tan(val_f)) or_return
	return
}

math_asin :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ASIN
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_ASIN
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.asin(val_f)) or_return
	return
}

math_acos :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ACOS
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_ACOS
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.acos(val_f)) or_return
	return
}

math_atan :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ATAN
	val := args[0]
	if (val.type != .INT && val.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_ATAN
	val_f: f32 = unpack_f32(val)
	obj = object.create_float(math.atan(val_f)) or_return
	return
}

math_atan2 :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ATAN2
	x := args[0]
	y := args[1]
	if (x.type != .INT && x.type != .FLOAT) || (y.type != .INT && y.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_ATAN2
	x_f: f32 = unpack_f32(x)
	y_f: f32 = unpack_f32(y)
	obj = object.create_float(math.atan2(x_f, y_f)) or_return
	return
}

math_log :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_LOG
	val := args[0]
	base := args[1]
	if (val.type != .INT && val.type != .FLOAT) || (base.type != .INT && base.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_LOG
	val_f: f32 = unpack_f32(val)
	base_f: f32 = unpack_f32(base)
	obj = object.create_float(math.log(val_f, base_f)) or_return
	return
}

math_hypot :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_HYPOT
	x := args[0]
	y := args[1]
	if (x.type != .INT && x.type != .FLOAT) || (y.type != .INT && y.type != .FLOAT) do return nil, .INCORRECT_PARAMETER_TYPE_IN_MATH_HYPOT
	x_f: f32 = unpack_f32(x)
	y_f: f32 = unpack_f32(y)
	obj = object.create_float(math.hypot(x_f, y_f)) or_return
	return
}
