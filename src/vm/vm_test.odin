package vm

import "core:testing"
import "../object"
import "../stack"
import "../types"

@(test)
create_initializes :: proc(t: ^testing.T) {
	v, code := create()
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, v != nil, "create should return a vm")
	testing.expectf(t, v.count == 0, "count should start at 0, got %d", v.count)
	testing.expectf(t, v.global_objects != nil, "global_objects should be initialized")
	testing.expectf(t, len(v.frames) == 0, "frames should start empty")
	destroy(v)
}

@(test)
copy_references_nil_errors :: proc(t: ^testing.T) {
	s, _ := stack.create()
	code := copy_references(nil, s)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_COPY_REFERENCES, "copy_references(nil, s) wrong code: %v", code)
	code = copy_references(s, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_COPY_REFERENCES, "copy_references(s, nil) wrong code: %v", code)
	delete(s.data)
	free(s)
}

@(test)
copy_references_copies :: proc(t: ^testing.T) {
	target, _ := stack.create()
	source, _ := stack.create()
	o1, _ := object.create_int(1)
	o2, _ := object.create_int(2)
	stack.push(source, o1)
	stack.push(source, o2)
	code := copy_references(target, source)
	testing.expectf(t, code == .OK, "copy_references failed: %v", code)
	testing.expectf(t, len(target.data) == 2, "target should have 2 references, got %d", len(target.data))
	testing.expectf(t, target.data[0] == o1, "target[0] should reference same object")
	testing.expectf(t, target.data[1] == o2, "target[1] should reference same object")
	stack.remove(target)
	delete(source.data)
	free(source)
}

@(test)
push_frame_adds_frame :: proc(t: ^testing.T) {
	v, _ := create()
	f, _ := stack.create()
	code := push_frame(v, f, false)
	testing.expectf(t, code == .OK, "push_frame failed: %v", code)
	testing.expectf(t, v.count == 1, "count should be 1, got %d", v.count)
	testing.expectf(t, len(v.frames) == 1, "frames should have 1, got %d", len(v.frames))
	destroy(v)
}

@(test)
push_frame_nil_errors :: proc(t: ^testing.T) {
	f, _ := stack.create()
	code := push_frame(nil, f, false)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_PUSH_FRAME, "push_frame(nil, f) wrong code: %v", code)
	v, _ := create()
	code = push_frame(v, nil, false)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_PUSH_FRAME, "push_frame(v, nil) wrong code: %v", code)
	destroy(v)
	delete(f.data)
	free(f)
}

@(test)
push_frame_inherits_current :: proc(t: ^testing.T) {
	v, _ := create()
	f1, _ := stack.create()
	o1, _ := object.create_int(1)
	o2, _ := object.create_int(2)
	stack.push(f1, o1)
	stack.push(f1, o2)
	push_frame(v, f1, false)
	f2, _ := stack.create()
	code := push_frame(v, f2, true)
	testing.expectf(t, code == .OK, "push_frame inherit failed: %v", code)
	testing.expectf(t, len(f2.data) == 2, "inheriting frame should copy 2 references, got %d", len(f2.data))
	testing.expectf(t, f2.parent_references == 2, "parent_references should be 2, got %d", f2.parent_references)
	destroy(v)
}

@(test)
current_frame_returns_top :: proc(t: ^testing.T) {
	v, _ := create()
	f1, _ := stack.create()
	f2, _ := stack.create()
	push_frame(v, f1, false)
	push_frame(v, f2, false)
	frame, code := current_frame(v)
	testing.expectf(t, code == .OK, "current_frame failed: %v", code)
	testing.expectf(t, frame == f2, "current_frame should return the most recent frame")
	testing.expectf(t, frame.global_data == v.global_objects, "current_frame should attach global_objects")
	destroy(v)
}

@(test)
current_frame_empty_errors :: proc(t: ^testing.T) {
	v, _ := create()
	frame, code := current_frame(v)
	testing.expectf(t, frame == nil, "current_frame on empty should return nil")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_CURRENT_FRAME, "current_frame empty wrong code: %v", code)
	_, code = current_frame(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_CURRENT_FRAME, "current_frame(nil) wrong code: %v", code)
	destroy(v)
}

@(test)
pop_frame_pops_top :: proc(t: ^testing.T) {
	v, _ := create()
	f, _ := stack.create()
	push_frame(v, f, false)
	code := pop_frame(v)
	testing.expectf(t, code == .OK, "pop_frame failed: %v", code)
	testing.expectf(t, v.count == 0, "count should be 0 after pop, got %d", v.count)
	testing.expectf(t, len(v.frames) == 0, "frames should be empty after pop")
	destroy(v)
}

@(test)
pop_frame_empty_errors :: proc(t: ^testing.T) {
	v, _ := create()
	code := pop_frame(v)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_POP_FRAME, "pop_frame empty wrong code: %v", code)
	code = pop_frame(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_POP_FRAME, "pop_frame(nil) wrong code: %v", code)
	destroy(v)
}

@(test)
pop_frame_frees_own_objects :: proc(t: ^testing.T) {
	v, _ := create()
	f, _ := stack.create()
	o1, _ := object.create_int(1)
	stack.push(f, o1)
	push_frame(v, f, false)
	code := pop_frame(v)
	testing.expectf(t, code == .OK, "pop_frame failed: %v", code)
	testing.expectf(t, len(v.frames) == 0, "frames should be empty after pop")
	destroy(v)
}

@(test)
destroy_nil_errors :: proc(t: ^testing.T) {
	code := destroy(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VM_DESTROY, "destroy(nil) wrong code: %v", code)
}

@(test)
destroy_empty :: proc(t: ^testing.T) {
	v, _ := create()
	code := destroy(v)
	testing.expectf(t, code == .OK, "destroy failed: %v", code)
}

@(test)
destroy_with_frames :: proc(t: ^testing.T) {
	v, _ := create()
	f1, _ := stack.create()
	f2, _ := stack.create()
	o1, _ := object.create_int(1)
	o2, _ := object.create_int(2)
	stack.push(f1, o1)
	stack.push(f1, o2)
	push_frame(v, f1, false)
	push_frame(v, f2, false)
	code := destroy(v)
	testing.expectf(t, code == .OK, "destroy failed: %v", code)
}