package stack

import "core:testing"
import "../object"
import "../types"

make_obj :: proc(value: int) -> (obj: ^types.object_t, code: types.exit_codes) {
	obj, _ = object.create_int(value)
	return
}

@(test)
create_initializes_fields :: proc(t: ^testing.T) {
	s, code := create()
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, s != nil, "create should return a stack")
	testing.expectf(t, s.count == 0, "count should start at 0, got %d", s.count)
	testing.expectf(t, s.capacity == 8, "capacity should be 8, got %d", s.capacity)
	testing.expectf(t, s.parent_references == 0, "parent_references should start at 0")
	testing.expectf(t, len(s.data) == 0, "data should start empty")
	remove(s)
}

@(test)
push_increments_count :: proc(t: ^testing.T) {
	s, _ := create()
	o, _ := make_obj(10)
	code := push(s, o)
	testing.expectf(t, code == .OK, "push failed: %v", code)
	testing.expectf(t, s.count == 1, "count should be 1, got %d", s.count)
	testing.expectf(t, len(s.data) == 1, "data length should be 1")
	remove(s)
}

@(test)
push_multiple :: proc(t: ^testing.T) {
	s, _ := create()
	for i in 0 ..< 3 {
		o, _ := make_obj(i)
		push(s, o)
	}
	testing.expectf(t, s.count == 3, "count should be 3, got %d", s.count)
	testing.expectf(t, s.capacity >= 3, "capacity should fit 3")
	remove(s)
}

@(test)
push_nil_tokens :: proc(t: ^testing.T) {
	s, _ := create()
	o, _ := make_obj(1)
	code := push(nil, o)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_STACK_PUSH, "push(nil, obj) wrong code: %v", code)
	code = push(s, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_STACK_PUSH, "push(stack, nil) wrong code: %v", code)
	remove(s)
}

@(test)
pop_empty_errors :: proc(t: ^testing.T) {
	s, _ := create()
	obj, code := pop(s)
	testing.expectf(t, obj == nil, "pop on empty should return nil")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_STACK_POP, "pop empty wrong code: %v", code)
	_, code = pop(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_STACK_POP, "pop(nil) wrong code: %v", code)
	remove(s)
}

@(test)
pop_lifo_order :: proc(t: ^testing.T) {
	s, _ := create()
	a, _ := make_obj(1)
	b, _ := make_obj(2)
	push(s, a)
	push(s, b)
	top, code := pop(s)
	testing.expectf(t, code == .OK, "pop failed: %v", code)
	testing.expectf(t, top.data.(int) == 2, "pop should return the most recently pushed")
	second, _ := pop(s)
	testing.expectf(t, second.data.(int) == 1, "second pop should return the first pushed")
	testing.expectf(t, s.count == 0, "count should be 0 after all pops")
	remove(s)
}

@(test)
remove_nil_errors :: proc(t: ^testing.T) {
	code := remove(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_STACK_REMOVE, "remove(nil) wrong code: %v", code)
}

@(test)
remove_releases_objects :: proc(t: ^testing.T) {
	s, _ := create()
	for i in 0 ..< 3 {
		o, _ := make_obj(i)
		push(s, o)
	}
	code := remove(s)
	testing.expectf(t, code == .OK, "remove failed: %v", code)
}

@(test)
get_by_name :: proc(t: ^testing.T) {
	s, _ := create()
	o, _ := make_obj(7)
	o.name = "x"
	push(s, o)
	got, code := get(s, "x")
	testing.expectf(t, code == .OK, "get failed: %v", code)
	testing.expectf(t, got != nil && got.name == "x", "get should return object named x")
	testing.expectf(t, got.data.(int) == 7, "get should return the right object")
	remove(s)
}

@(test)
get_missing_returns_nil :: proc(t: ^testing.T) {
	s, _ := create()
	o, _ := make_obj(7)
	o.name = "x"
	push(s, o)
	got, _ := get(s, "missing")
	testing.expectf(t, got == nil, "get of missing name should return nil")
	remove(s)
}

@(test)
get_searches_global_data :: proc(t: ^testing.T) {
	s, _ := create()
	global, _ := create()
	s.global_data = global
	go, _ := make_obj(5)
	go.name = "g"
	push(global, go)
	got, _ := get(s, "g")
	testing.expectf(t, got != nil && got.name == "g", "get should find object in global_data")
	remove(s)
}

@(test)
get_nil_stack_errors :: proc(t: ^testing.T) {
	obj, code := get(nil, "x")
	testing.expectf(t, obj == nil, "get(nil) should return nil")
	testing.expectf(t, code == .OBJECT_IS_NIL_STACK_GET, "get(nil) wrong code: %v", code)
}

@(test)
remove_object_removes_by_name :: proc(t: ^testing.T) {
	s, _ := create()
	world, _ := create()
	s.global_data = world
	a, _ := make_obj(1)
	a.name = "a"
	b, _ := make_obj(2)
	b.name = "b"
	push(s, a)
	push(s, b)
	code := remove_object(s, "a")
	testing.expectf(t, code == .OK, "remove_object failed: %v", code)
	got, _ := get(s, "a")
	testing.expectf(t, got == nil, "a should no longer be present")
	still, _ := get(s, "b")
	testing.expectf(t, still != nil && still.name == "b", "b should remain")
	remove(s)
}

@(test)
remove_object_global :: proc(t: ^testing.T) {
	s, _ := create()
	world, _ := create()
	s.global_data = world
	go, _ := make_obj(9)
	go.name = "gg"
	push(world, go)
	local, _ := make_obj(1)
	local.name = "gg"
	push(s, local)
	remove_object(s, "gg")
	got, _ := get(s, "gg")
	testing.expectf(t, got == nil, "gg should be removed from both data and global_data")
	remove(s)
}

@(test)
remove_object_errors :: proc(t: ^testing.T) {
	code := remove_object(nil, "x")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_STACK_REMOVE_OBJECT, "remove_object(nil) wrong code: %v", code)
}

@(test)
remove_nulls_compacts :: proc(t: ^testing.T) {
	s, _ := create()
	world, _ := create()
	s.global_data = world
	a, _ := make_obj(1)
	a.name = "a"
	b, _ := make_obj(2)
	b.name = "b"
	push(s, a)
	push(s, b)
	append(&s.data, nil)
	g, _ := make_obj(3)
	push(world, g)
	append(&world.data, nil)
	code := remove_nulls(s)
	testing.expectf(t, code == .OK, "remove_nulls failed: %v", code)
	testing.expectf(t, len(s.data) == 2, "data should be compacted to 2, got %d", len(s.data))
	testing.expectf(t, len(world.data) == 1, "global data should be compacted to 1, got %d", len(world.data))
	remove(s)
}