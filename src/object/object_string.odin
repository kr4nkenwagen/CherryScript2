package object

import "../object"
import "../sys"
import "../types"
import "core:fmt"
import "core:strings"

int_len :: proc(n: int) -> (ret_int: int, code: types.exit_codes) {
	if n == 0 {
		return 1, .OK
	}
	ret_int = 0
	num := abs(n)
	for num > 0 {
		num /= 10
		ret_int += 1
	}
	return
}

float_len :: proc(n: f32) -> (ret_int: int, code: types.exit_codes) {
	s := fmt.tprintf("%v", n)
	ret_int = len(s)
	return
}

int_to_number :: proc(num: int) -> (ret_str: string, codes: types.exit_codes) {
	ret_str = fmt.tprintf("%d", num)
	return
}

float_to_number :: proc(num: f32) -> (ret_str: string, code: types.exit_codes) {
	ret_str = fmt.tprintf("%g", num)
	return
}

join_string :: proc(
	a: ^types.object_t,
	b: ^types.object_t,
	allocator := context.allocator,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	a_str, b_str: string
	if a.type == .INT {
		a_str, _ = int_to_number(a.data.(int))
	} else if a.type == .FLOAT {
		a_str, _ = float_to_number(a.data.(f32))
	} else if a.type == .STRING {
		a_str = a.data.(string)
	} else {
		return nil, .FAILED_TO_CONCAT_STRING_OBJECT_A_IN_OBJECT_STRING_JOIN_STRING
	}
	if b.type == .INT {
		b_str, _ = int_to_number(b.data.(int))
	} else if b.type == .FLOAT {
		b_str, _ = float_to_number(b.data.(f32))

	} else if b.type == .STRING {
		b_str = b.data.(string)
	} else {
		return nil, .FAILED_TO_CONCAT_STRING_OBJECT_B_IN_OBJECT_STRING_JOIN_STRING
	}
	res, err := strings.concatenate({a_str, b_str}, allocator)
	if err != .None {
		return nil, .FAILED_TO_CONCAT_STRING_OBJECT_B_IN_OBJECT_STRING_JOIN_STRING
	}
	ret_obj = create_string(res) or_return
	return
}

position_of_first_instance :: proc(
	obj: ^types.object_t,
	instance: string,
) -> (
	ret_int: int,
	code: types.exit_codes,
) {
	ret_int = -1
	if obj == nil {
		return ret_int, .OBJECT_IS_NIL_IN_OBJECT_STRING_POSITION_OF_FIST_INSTANCE
	}
	if obj.type != .STRING {
		return ret_int,
			.STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_POSITION_OF_FIRST_INSTANCE
	}
	obj_size, err := object.length(obj)
	if sys.is_error(err) {
		return ret_int, err
	}
	instance_size := len(instance)
	if instance_size == 0 {
		return
	}
	position := 0
	for position := 0; position + instance_size <= obj_size; position += 1 {
		if obj.data.(string)[position:position + instance_size] == instance {
			ret_int = position
			return
		}
	}
	return
}

position_of_last_instance :: proc(
	obj: ^types.object_t,
	instance: string,
) -> (
	ret_int: int,
	code: types.exit_codes,
) {
	if obj == nil {
		return -1, .OBJECT_IS_NIL_IN_OBJECT_STRING_POSITION_OF_LAST_INSTANCE
	}
	if obj.type != .STRING {
		return -1,
			.STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_POSITION_OF_LAST_INSTANCE
	}
	if len(instance) == 0 {
		return -1, .OK
	}
	src := obj.data.(string)
	ret_int = strings.last_index(src, instance)
	return
}

substring :: proc(
	obj: ^types.object_t,
	start: int,
	length: int,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if obj == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_SUBSTRING
	}
	if obj.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_SUBSTRING
	}
	obj_size, obj_err := object.length(obj)
	if sys.is_error(obj_err) {
		return nil, obj_err
	}
	if start < 0 || start > obj_size {
		return nil, .SUBSTRING_START_OUT_OF_BOUNDS_IN_OBJECT_STRING_SUBSTRING
	}
	input_length := length
	if length == -1 {
		input_length = obj_size - start
	}
	if input_length < 0 {
		return nil, .SUBSTRING_LENGTH_TO_LESS_THAN_ZERO_IN_OBJECT_STRING_SUBSTRING
	}
	if start + input_length > obj_size {
		return nil, .SUBSTRING_LENGTH_TO_LONG_IN_OBJECT_STRING_SUBSTRING
	}
	end_index := start + input_length
	ret_obj = object.create_string(obj.data.(string)[start:end_index]) or_return
	return
}

strip_instances_from_string :: proc(
	target, instance: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if target == nil || instance == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_STRIP_INSTANCE_FROM_STRING
	}
	if target.type != .STRING || instance.type != .STRING {
		return nil,
			.STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_STRIP_INSTANCE_FROM_STRING
	}
	target_str := target.data.(string)
	instance_str := instance.data.(string)
	if len(instance_str) == 0 {
		return object.create_string(target_str)
	}

	res, err := strings.replace_all(target_str, instance_str, "", context.allocator)
	if !err {
		return nil, .STRING_REPLACE_FAIL_IN_OBJECT_STRING_STRIP_INSTAANCE_FROM_STRING
	}
	ret_obj = object.create_string(res) or_return
	return
}

lengthen_string :: proc(
	target, length: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if target == nil || length == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_LENGTHEN_STRING
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT_INOBJECT_STRING_LENGTHEN_STRING
	}
	len_val: int
	if length.type == .INT {
		len_val = int(length.data.(int))
	} else if length.type == .FLOAT {
		len_val = int(length.data.(f32))
	} else {
		return nil, .TYPE_MISMATCH_IN_OBJECT_STRING_LENGTHEN_STRING
	}
	if len_val <= 0 {
		return object.create_string(target.data.(string))
	}
	target_size := object.length(target) or_return
	if target_size == 0 {
		return object.create_string("")
	}
	src := target.data.(string)
	new_size := target_size + len_val
	buf := make([]byte, new_size)
	for i := 0; i < new_size; i += 1 {
		buf[i] = src[i % target_size]
	}
	ret_obj = object.create_string(string(buf)) or_return
	return
}

shorten_string :: proc(
	target, length: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if target == nil || length == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_SHORTEN_STRING
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_SHORTEN_STRING
	}
	if length.type != .INT {
		return nil, .TYPE_MISMATCH_IN_OBJECT_STRING_SHORTEN_STRING
	}
	len_val := int(length.data.(int))
	if len_val <= 0 {
		return object.create_string(target.data.(string))
	}
	target_size := object.length(target) or_return
	if len_val >= target_size {
		return object.create_string("")
	}
	new_size := target_size - len_val
	ret_obj = object.create_string(target.data.(string)[0:new_size]) or_return
	return
}

multiply_string :: proc(
	target, multiplier: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if target == nil || multiplier == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_MULTIPLY_STRING
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_MULTIPLY_STRING
	}
	if multiplier.type != .INT {
		return nil, .TYPE_MISMATCH_IN_OBJECT_STRING_MULTIPLY_STRING
	}
	mult_val := int(multiplier.data.(int))
	if mult_val < 0 {
		return nil, .INVALID_MULTIPLIER_IN_OBJECT_STRING_MULTIPLY_STRING
	}
	if mult_val == 0 {
		return object.create_string("")
	}
	res, alloc_err := strings.repeat(target.data.(string), mult_val, context.allocator)
	if alloc_err != .None {
		return nil, .FAILED_TO_ALLOCATE_STRING_IN_OBJECT_STRING_MULTIPLY_STRING
	}
	ret_obj = object.create_string(res) or_return
	return
}

divide_string :: proc(
	target, divider: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if target == nil || divider == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_DIVIDE_STRING
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_DIVIDE_STRING
	}
	if divider.type != .INT {
		return nil, .TYPE_MISMATCH_OBJECT_STRING_DIVIDE_STRING
	}
	div_val := int(divider.data.(int))
	if div_val <= 0 {
		return nil, .DIVISION_BY_ZERO_IN_OBJECT_STRING_DIVIDE_STRING
	}
	target_size := object.length(target) or_return
	new_size := target_size / div_val
	ret_obj = object.create_string(target.data.(string)[0:new_size]) or_return
	return
}

modulus_string :: proc(
	target, modulus: ^types.object_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if target == nil || modulus == nil {
		return nil, .OBJECT_IS_NIL_IN_OBJECT_STRING_MODULUS_STRING
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_MODULUS_STRING
	}
	if modulus.type != .INT {
		return nil, .TYPE_MISMATCH_IN_OBJECT_STRING_MODULUS_STRING
	}
	mod_val := int(modulus.data.(int))
	if mod_val <= 0 {
		return nil, .DIVISION_BY_ZERO_IN_OBJECT_STRING_MODULUS_STRING
	}
	target_size := object.length(target) or_return
	new_size := target_size % mod_val
	start := target_size - new_size
	ret_obj = object.create_string(target.data.(string)[start:target_size]) or_return
	return
}
