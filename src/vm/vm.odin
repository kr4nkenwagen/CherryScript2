package vm

import "../stack"
import "../types"

create :: proc() -> (^types.vm_t, types.exit_codes) {
	vm := new(types.vm_t)
	if vm == nil {
		return nil, .OBJECT_IS_NIL
	}
	vm.count = 0
	return vm, .OK
}

copy_references :: proc(target: ^types.stack_t, source: ^types.stack_t) -> types.exit_codes {
	if target == nil || source == nil {
		return .OBJECT_IS_NIL
	}
	i := 0
	for i < source.count {
		stack.push(target, source.data[i])
		i += 1
	}
	return .OK
}

push_frame :: proc(
	vm: ^types.vm_t,
	stack: ^types.stack_t,
	inherit_stack: bool,
) -> types.exit_codes {
	if vm == nil {
		return .OBJECT_IS_NIL
	}
	if inherit_stack {
		curr_frame, _ := current_frame(vm)
		copy_references(stack, curr_frame)
		stack.parent_references = stack.count
	}
	append(&vm.frames, stack)
	vm.count += 1
	return .OK
}

pop_frame :: proc(vm: ^types.vm_t) -> types.exit_codes {
	if vm == nil || vm.count == 0 {
		return .OBJECT_IS_NIL
	}
	frame, _ := current_frame(vm)
	i := frame.parent_references
	for i < frame.count {
		free(frame.data[i])
		frame.data[i] = nil
		i += 1
	}
	free(frame)
	vm.count -= 1
	return .OK
}

current_frame :: proc(vm: ^types.vm_t) -> (^types.stack_t, types.exit_codes) {
	if vm == nil || vm.count == 0 {
		return nil, .OBJECT_IS_NIL
	}
	return vm.frames[vm.count - 1], .OK
}
