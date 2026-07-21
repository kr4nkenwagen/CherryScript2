package stack

import "../types"
import "base:builtin"

create :: proc() -> (^types.stack_t, types.exit_codes) {
	stack := new(types.stack_t)
	if stack == nil {
		return nil, .OBJECT_IS_NIL
	}
	reserve(&stack.data, 8)
	stack.capacity = 8
	stack.count = 0
	stack.parent_references = 0
	return stack, .OK
}

push :: proc(stack: ^types.stack_t, object: ^types.object_t) -> types.exit_codes {
	if stack == nil || object == nil {
		return .OBJECT_IS_NIL
	}
	append(&stack.data, object)
	stack.count = len(stack.data)
	stack.capacity = cap(stack.data)
	return .OK
}

pop :: proc(stack: ^types.stack_t) -> (^types.object_t, types.exit_codes) {
	if stack == nil || len(stack.data) == 0 {
		return nil, .OBJECT_IS_NIL
	}
	obj := builtin.pop(&stack.data)
	stack.count = len(stack.data)
	return obj, .OK
}

remove :: proc(stack: ^types.stack_t) -> types.exit_codes {
	if stack == nil {
		return .OBJECT_IS_NIL
	}
	for obj in stack.data {
		if obj != nil {
			free(obj)
		}
	}
	delete(stack.data)
	free(stack)
	return .OK
}

remove_nulls :: proc(stack: ^types.stack_t) -> types.exit_codes {
	if stack == nil {
		return .OBJECT_IS_NIL
	}
	new_count := 0
	for obj in stack.data {
		if obj != nil {
			stack.data[new_count] = obj
			new_count += 1
		}
	}
	resize(&stack.data, new_count)
	stack.count = new_count
	return .OK
}

get :: proc(stack: ^types.stack_t, name: string) -> (^types.object_t, types.exit_codes) {
	if stack == nil {
		return nil, .OBJECT_IS_NIL
	}
	for obj in stack.data {
		if obj != nil && obj.name == name {
			return obj, .OK
		}
	}
	return nil, .OK
}

remove_object :: proc(stack: ^types.stack_t, name: string) -> types.exit_codes {
	if stack == nil {
		return .OBJECT_IS_NIL
	}
	for i := 0; i < len(stack.data); i += 1 {
		if stack.data[i] != nil && stack.data[i].name == name {
			free(stack.data[i])
			stack.data[i] = nil
		}
	}
	remove_nulls(stack)
	return .OK
}
