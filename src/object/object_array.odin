package object

import "../object"
import "../sys"
import "../types"

array_set :: proc(arr: ^types.object_t, index: int, obj: ^types.object_t) -> types.exit_codes {
	if arr == nil {
		return .OBJECT_IS_NIL
	}
	if arr.type != .ARRAY {
		return .ARRAY_OPERATION_ON_NON_ARRAY_OBJECT
	}
	data := arr.data.(types.object_array_t)
	if index > data.count {
		for i := data.count; i < index; i += 1 {
			nil_obj, nil_obj_err := object.create_null()
			data.count += 1
			if sys.is_error(nil_obj_err) {
				return nil_obj_err
			}
			append(&data.value, nil_obj)
			data.count += 1
		}
	}
	return .OK
}

array_get :: proc(arr: ^types.object_t, index: int) -> (^types.object_t, types.exit_codes) {
	if arr == nil {
		return nil, .OBJECT_IS_NIL
	}
	if arr.type != .ARRAY {
		return nil, .ARRAY_OPERATION_ON_NON_ARRAY_OBJECT
	}
	if index >= arr.data.(types.object_array_t).count {
		return nil, .INDEX_OUT_OF_BOUNDS
	}

	return arr.data.(types.object_array_t).value[index], .OK
}
