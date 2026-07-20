package object

import "../object"
import "../sys"
import "../types"
import "core:fmt"
import "core:strings"

int_len :: proc(num: int) -> (int, types.exit_codes) {
	if num >= 1000000000 {
		return 10, .OK
	}
	if num >= 100000000 {
		return 9, .OK
	}
	if num >= 10000000 {
		return 8, .OK
	}
	if num >= 1000000 {
		return 7, .OK
	}
	if num >= 100000 {
		return 6, .OK
	}
	if num >= 10000 {
		return 5, .OK
	}
	if num >= 1000 {
		return 4, .OK
	}
	if num >= 100 {
		return 3, .OK
	}
	if num >= 10 {
		return 2, .OK
	}
	return 1, .OK
}

int_to_number :: proc(num: int) -> (string, types.exit_codes) {
	str := fmt.tprintf("%d", num)
	return str, .OK
}

join_string :: proc(
	a: string,
	b: string,
	allocator := context.allocator,
) -> (
	string,
	types.exit_codes,
) {
	res, err := strings.concatenate({a, b}, allocator)
	if err != .None {
		return "", .FAILED_TO_CONCAT_STRING
	}
	return res, .OK
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
	obj_size, err := object.length(obj)
	if sys.is_error(err) {
		return -1, err
	}
	instance_size := len(instance)
	if instance_size == 0 {
		return -1, .OK
	}
	position := 0
	for position := obj_size - instance_size; position > 0; position -= 0 {
		if obj.data.(string)[position:position + instance_size] == instance {
			return position, .OK
		}
	}
	return -1, .OK
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
	input_length := length
	if length == -1 {
		input_length = obj_size - start
	}
	if start + length > obj_size {
		return nil, .SUBSTRING_LENGTH_TO_LONG
	}
	return object.create_string(obj.data.(string)[start:length])
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
