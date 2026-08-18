package vm

import "../stack"
import "../types"

create :: proc() -> (vmem: ^types.vm_t, code: types.exit_codes) {
	vm := new(types.vm_t)
	if vm == nil do return nil, .OBJECT_IS_NIL
	global_err: types.exit_codes
	vm.global_objects = stack.create() or_return
	vm.count = 0
	return vm, .OK
}

copy_references :: proc(target: ^types.stack_t, source: ^types.stack_t) -> types.exit_codes {
	if target == nil || source == nil do return .OBJECT_IS_NIL
	for obj in source.data do stack.push(target, obj)
	return .OK
}

push_frame :: proc(
	stck: ^types.vm_t,
	frame_stack: ^types.stack_t,
	inherit_stack: bool,
) -> types.exit_codes {
	if stck == nil || frame_stack == nil do return .OBJECT_IS_NIL

	if inherit_stack && len(stck.frames) > 0 {
		curr_frame, err := current_frame(stck)
		if err == .OK && curr_frame != nil {
			copy_references(frame_stack, curr_frame)
			frame_stack.parent_references = len(frame_stack.data)
		}
	}
	append(&stck.frames, frame_stack)
	stck.count = len(stck.frames)
	return .OK
}

pop_frame :: proc(stck: ^types.vm_t) -> types.exit_codes {
	if stck == nil || len(stck.frames) == 0 do return .OBJECT_IS_NIL
	frame := pop(&stck.frames)
	if frame == nil do return .OBJECT_IS_NIL
	if frame.parent_references < len(frame.data) {
		for obj in frame.data[frame.parent_references:] {
			if obj != nil do free(obj)
		}
	}
	stck.count = len(stck.frames)
	delete(frame.data)
	free(frame)
	stck.count = len(stck.frames)
	return .OK
}

current_frame :: proc(stck: ^types.vm_t) -> (^types.stack_t, types.exit_codes) {
	if stck == nil || len(stck.frames) == 0 do return nil, .OBJECT_IS_NIL
	stack := stck.frames[len(stck.frames) - 1]
	if stack.global_data == nil do stack.global_data = stck.global_objects
	return stack, .OK
}

destroy :: proc(vm: ^types.vm_t) -> types.exit_codes {
	if vm == nil do return .OBJECT_IS_NIL
	for len(vm.frames) > 0 do pop_frame(vm)
	delete(vm.frames)
	if vm.global_objects != nil do stack.remove(vm.global_objects)
	free(vm)
	return .OK
}
