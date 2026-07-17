package vm

import "../stack"
import "../types"

create :: proc() -> (^types.vm_t, bool) {
	vm := new(types.vm_t)
	if vm == nil {
		return nil, true
	}
	vm.count = 0
	return vm, false
}

copy_references :: proc(target: ^types.stack_t, source: ^types.stack_t) -> bool {
	if target == nil || source == nil {
		return true
	}
	i := 0
	for i < source.count {
		stack.push(target, source.data[i])
		i += 1
	}
	return false
}

push_frame :: proc(vm: ^types.vm_t, stack: ^types.stack_t, inherit_stack: bool) -> bool {
	if vm == nil {
		return true
	}
	if inherit_stack {
		curr_frame, _ := current_frame(vm)
		copy_references(stack, curr_frame)
		stack.parent_references = stack.count
	}
	vm.frames[vm.count] = stack
	vm.count += 1
	return false
}

pop_frame :: proc(vm: ^types.vm_t) -> bool {
	if vm == nil || vm.count == 0 {
		return true
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
	return false
}

current_frame :: proc(vm: ^types.vm_t) -> (^types.stack_t, bool) {
	if vm == nil || vm.count == 0 {
		return nil, true
	}
	return vm.frames[vm.count - 1], false
}
