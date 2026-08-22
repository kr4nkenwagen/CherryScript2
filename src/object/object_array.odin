package object

import "../object"
import "../types"

array_set :: proc(
	arr: ^types.object_t,
	index: int,
	obj: ^types.object_t,
) -> (
	codes: types.exit_codes,
) {
	if arr == nil {
		return .OBJECT_IS_NIL_IN_ARRAY_SET
	}
	if arr.type != .ARRAY {
		return .ARRAY_OPERATION_ON_NON_ARRAY_OBJECT_IN_ARRAY_SET
	}
	data := arr.data.(types.object_array_t)
	if index > data.count {
		for i := data.count; i < index; i += 1 {
			nil_obj := object.create_null() or_return
			append(&data.value, nil_obj)
			data.count += 1
		}
	}
	if index == data.count {
		append(&data.value, obj)
		data.count += 1
	} else {
		free(data.value[index])
		data.value[index] = obj
	}
	arr.data = data
	return
}

array_get :: proc(
	arr: ^types.object_t,
	index: int,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	if arr == nil do return nil, .OBJECT_IS_NIL_IN_ARRAY_GET
	if arr.type != .ARRAY do return nil, .ARRAY_OPERATION_ON_NON_ARRAY_OBJECT_IN_ARRAY_GET
	if index >= arr.data.(types.object_array_t).count {
		null_obj := object.create_null() or_return
		array_set(arr, index, null_obj) or_return
	}
	ret_obj = arr.data.(types.object_array_t).value[index]
	return
}
