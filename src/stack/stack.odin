package stack

import "../types"

create :: proc() -> (^types.stack_t, bool) {
	stack := new(types.stack_t)
	if stack == nil {
		return nil, true
	}
	stack.capacity = 8
	stack.count = 0
	stack.parent_references = 0
	return stack, false
}

push :: proc(stack: ^types.stack_t, object: ^types.object_t) -> bool {
	if object == nil || stack == nil {
		return true
	}
	stack.count += 1
	append(&stack.data, object)
	return false
}

pop :: proc(stack: ^types.stack_t) -> (^types.object_t, bool) {
	if stack == nil {
		return nil, true
	}
	stack.count -= 1
	return stack.data[stack.count], false
}

remove :: proc(stack: ^types.stack_t) -> bool {
	if stack == nil {
		return true
	}
	i := 0
	for i < stack.count {
		free(stack.data[i])
		i += 1
	}
	free(stack)
	return false
}

remove_nulls :: proc(stack: ^types.stack_t) -> bool {
	if stack == nil {
		return true
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
	return false
}

get :: proc(stack: ^types.stack_t, name: string) -> (^types.object_t, bool) {
	if stack == nil {
		return nil, true
	}
	i := 0
	for i < stack.count {
		if stack.data[i].name == name {
			return stack.data[i], false
		}
	}
	return nil, true
}

remove_object :: proc(stack: ^types.stack_t, name: string) -> bool {
	if stack == nil {
		return true
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
	return false
}
