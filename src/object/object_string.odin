package object

import "../object"
import "../sys"
import "../types"
import "core:fmt"
import "core:strings"

int_len :: proc(n: int) -> (int, types.exit_codes) {
	if n == 0 {
		return 1, .OK
	}
	count := 0
	num := abs(n)
	for num > 0 {
		num /= 10
		count += 1
	}
	return count, .OK
}

float_len :: proc(n: f32) -> (int, types.exit_codes) {
	s := fmt.tprintf("%v", n)
	return len(s), .OK
}

int_to_number :: proc(num: int) -> (string, types.exit_codes) {
	str := fmt.tprintf("%d", num)
	return str, .OK
}

join_string :: proc(
	a: ^types.object_t,
	b: ^types.object_t,
	allocator := context.allocator,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	a_str, b_str: string
	if a.type == .INT {
		a_str, _ = int_to_number(a.data.(int))
	} else if a.type == .STRING {
		a_str = a.data.(string)
	} else {
		return nil, .FAILED_TO_CONCAT_STRING
	}
	if b.type == .INT {
		b_str, _ = int_to_number(b.data.(int))
	} else if b.type == .STRING {
		b_str = b.data.(string)
	} else {
		return nil, .FAILED_TO_CONCAT_STRING
	}
	res, err := strings.concatenate({a_str, b_str}, allocator)
	if err != .None {
		return nil, .FAILED_TO_CONCAT_STRING
	}
	return create_string(res)
}

position_of_first_instance :: proc(
	obj: ^types.object_t,
	instance: string,
) -> (
	int,
	types.exit_codes,
) {
	if obj == nil {
		return -1, .OBJECT_IS_NIL
	}
	if obj.type != .STRING {
		return -1, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	obj_size, err := object.length(obj)
	if sys.is_error(err) {
		return -1, err
	}
	instance_size := len(instance)
	if instance_size == 0 {
		return -1, .OK
	}
	position := 0
	for position := 0; position + instance_size <= obj_size; position += 1 {
		if obj.data.(string)[position:position + instance_size] == instance {
			return position, .OK
		}
	}
	return -1, .OK
}

position_of_last_instance :: proc(
	obj: ^types.object_t,
	instance: string,
) -> (
	int,
	types.exit_codes,
) {
	if obj == nil {
		return -1, .OBJECT_IS_NIL
	}
	if obj.type != .STRING {
		return -1, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	if len(instance) == 0 {
		return -1, .OK
	}
	src := obj.data.(string)
	position := strings.last_index(src, instance)
	return position, .OK
}

substring :: proc(
	obj: ^types.object_t,
	start: int,
	length: int,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if obj == nil {
		return nil, .OBJECT_IS_NIL
	}
	if obj.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	obj_size, obj_err := object.length(obj)
	if sys.is_error(obj_err) {
		return nil, obj_err
	}
	if start < 0 || start > obj_size {
		return nil, .SUBSTRING_LENGTH_TO_LONG
	}
	input_length := length
	if length == -1 {
		input_length = obj_size - start
	}
	if input_length < 0 {
		return nil, .SUBSTRING_LENGTH_TO_LONG
	}
	if start + input_length > obj_size {
		return nil, .SUBSTRING_LENGTH_TO_LONG
	}
	end_index := start + input_length
	return object.create_string(obj.data.(string)[start:end_index])
}

strip_instances_from_string :: proc(
	target, instance: ^types.object_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if target == nil || instance == nil {
		return nil, .OBJECT_IS_NIL
	}
	if target.type != .STRING || instance.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	target_str := target.data.(string)
	instance_str := instance.data.(string)
	if len(instance_str) == 0 {
		return object.create_string(target_str)
	}

	res, err := strings.replace_all(target_str, instance_str, "", context.allocator)
	if !err {
		return nil, .STRING_REPLACE_FAIL
	}
	return object.create_string(res)
}

lengthen_string :: proc(target, length: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if target == nil || length == nil {
		return nil, .OBJECT_IS_NIL
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	len_val: int
	if length.type == .INT {
		len_val = int(length.data.(int))
	} else if length.type == .FLOAT {
		len_val = int(length.data.(f32))
	} else {
		return nil, .TYPE_MISMATCH
	}
	if len_val <= 0 {
		return object.create_string(target.data.(string))
	}
	target_size, err := object.length(target)
	if sys.is_error(err) {
		return nil, err
	}
	if target_size == 0 {
		return object.create_string("")
	}
	src := target.data.(string)
	new_size := target_size + len_val
	buf := make([]byte, new_size)
	for i := 0; i < new_size; i += 1 {
		buf[i] = src[i % target_size]
	}
	return object.create_string(string(buf))
}

shorten_string :: proc(target, length: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if target == nil || length == nil {
		return nil, .OBJECT_IS_NIL
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	if length.type != .INT {
		return nil, .TYPE_MISMATCH
	}
	len_val := int(length.data.(int))
	if len_val <= 0 {
		return object.create_string(target.data.(string))
	}
	target_size, err := object.length(target)
	if sys.is_error(err) {
		return nil, err
	}
	if len_val >= target_size {
		return object.create_string("")
	}

	new_size := target_size - len_val
	return object.create_string(target.data.(string)[0:new_size])
}

multiply_string :: proc(
	target, multiplier: ^types.object_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if target == nil || multiplier == nil {
		return nil, .OBJECT_IS_NIL
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	if multiplier.type != .INT {
		return nil, .TYPE_MISMATCH
	}
	mult_val := int(multiplier.data.(int))
	if mult_val < 0 {
		return nil, .INVALID_MULTIPLIER
	}
	if mult_val == 0 {
		return object.create_string("")
	}

	res, alloc_err := strings.repeat(target.data.(string), mult_val, context.allocator)
	if alloc_err != .None {
		return nil, .FAILED_TO_ALLOCATE_STRING
	}
	return object.create_string(res)
}

divide_string :: proc(target, divider: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if target == nil || divider == nil {
		return nil, .OBJECT_IS_NIL
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	if divider.type != .INT {
		return nil, .TYPE_MISMATCH
	}
	div_val := int(divider.data.(int))
	if div_val <= 0 {
		return nil, .DIVISION_BY_ZERO
	}
	target_size, err := object.length(target)
	if sys.is_error(err) {
		return nil, err
	}
	new_size := target_size / div_val
	return object.create_string(target.data.(string)[0:new_size])
}

modulus_string :: proc(target, modulus: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	if target == nil || modulus == nil {
		return nil, .OBJECT_IS_NIL
	}
	if target.type != .STRING {
		return nil, .STRING_OPERATION_ON_NON_STRING_OBJECT
	}
	if modulus.type != .INT {
		return nil, .TYPE_MISMATCH
	}
	mod_val := int(modulus.data.(int))
	if mod_val <= 0 {
		return nil, .DIVISION_BY_ZERO
	}
	target_size, err := object.length(target)
	if sys.is_error(err) {
		return nil, err
	}
	new_size := target_size % mod_val
	start := target_size - new_size
	return object.create_string(target.data.(string)[start:target_size])
}
