package stack

import "../types"

create :: proc() -> (^types.stack_t, types.exit_codes) {
	stack := new(types.stack_t)
	if stack == nil {
		return nil, .OBJECT_IS_NIL
	}
	stack.capacity = 8
	stack.count = 0
	stack.parent_references = 0
	return stack, .OK
}

push :: proc(stack: ^types.stack_t, object: ^types.object_t) -> types.exit_codes {
	if object == nil || stack == nil {
		return .OBJECT_IS_NIL
	}
	stack.count += 1
	append(&stack.data, object)
	return .OK
}

pop :: proc(stack: ^types.stack_t) -> (^types.object_t, types.exit_codes) {
	if stack == nil {
		return nil, .OBJECT_IS_NIL
	}
	stack.count -= 1
	return stack.data[stack.count], .OK
}

remove :: proc(stack: ^types.stack_t) -> types.exit_codes {
	if stack == nil {
		return .OBJECT_IS_NIL
	}
	i := 0
	for i < stack.count {
		free(stack.data[i])
		i += 1
	}
	free(stack)
	return .OK
}

remove_nulls :: proc(stack: ^types.stack_t) -> types.exit_codes {
	if stack == nil {
		return .OBJECT_IS_NIL
	}
	new_count := 0
	i := 0
	for i < stack.count {
		if stack.data[i] != nil {
			stack.data[new_count] = stack.data[i]
			new_count += 1
		}
	}
	i += 1
	stack.count = new_count
	return .OK
}

get :: proc(stack: ^types.stack_t, name: string) -> (^types.object_t, types.exit_codes) {
	if stack == nil {
		return nil, .OBJECT_IS_NIL
	}
	for i := 0; i < stack.count; i += 1 {
		if stack.data[i].name == name {
			return stack.data[i], .OK
		}
	}
	return nil, .OK
}

remove_object :: proc(stack: ^types.stack_t, name: string) -> types.exit_codes {
	if stack == nil {
		return .OBJECT_IS_NIL
	}
	i := 0
	for i < stack.count {
		if stack.data[i].name == name {
			free(stack.data[i])
			stack.data[i] = nil
		}
		i += 1
	}
	remove_nulls(stack)
	return .OK
}
