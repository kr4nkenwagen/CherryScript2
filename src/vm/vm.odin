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
	for obj in source.data {
		stack.push(target, obj)
	}
	return .OK
}

push_frame :: proc(
	vm: ^types.vm_t,
	frame_stack: ^types.stack_t,
	inherit_stack: bool,
) -> types.exit_codes {
	if vm == nil || frame_stack == nil {
		return .OBJECT_IS_NIL
	}

	if inherit_stack && len(vm.frames) > 0 {
		curr_frame, err := current_frame(vm)
		if err == .OK && curr_frame != nil {
			copy_references(frame_stack, curr_frame)
			frame_stack.parent_references = len(frame_stack.data)
		}
	}

	append(&vm.frames, frame_stack)
	vm.count = len(vm.frames)
	return .OK
}

pop_frame :: proc(vm: ^types.vm_t) -> types.exit_codes {
	if vm == nil || len(vm.frames) == 0 {
		return .OBJECT_IS_NIL
	}
	frame := pop(&vm.frames)
	if frame == nil {
		return .OBJECT_IS_NIL
	}
	if frame.parent_references < len(frame.data) {
		for obj in frame.data[frame.parent_references:] {
			if obj != nil {
				free(obj)
			}
		}
	}
	vm.count = len(vm.frames)
	delete(frame.data)
	free(frame)

	vm.count = len(vm.frames)
	return .OK
}

current_frame :: proc(vm: ^types.vm_t) -> (^types.stack_t, types.exit_codes) {
	if vm == nil || len(vm.frames) == 0 {
		return nil, .OBJECT_IS_NIL
	}
	return vm.frames[len(vm.frames) - 1], .OK
}
