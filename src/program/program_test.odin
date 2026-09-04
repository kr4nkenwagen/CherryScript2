package program

import "core:testing"
import "core:time"
import "../syntax"
import "../types"

prgm_teardown :: proc(p: ^types.program_t) {
	delete(p.statements)
	if p.parent == nil && p.stats != nil {
		if p.stats.start_time != nil do free(p.stats.start_time)
		free(p.stats)
	}
	free(p)
}

@(test)
create_initializes_root :: proc(t: ^testing.T) {
	p, code := create(nil)
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, p != nil, "create should return a program")
	testing.expectf(t, p.length == 0, "length should start at 0")
	testing.expectf(t, p.pointer == 0, "pointer should start at 0")
	testing.expectf(t, p.exit == false, "exit should start false")
	testing.expectf(t, p.breaking == false, "breaking should start false")
	testing.expectf(t, p.continueing == false, "continueing should start false")
	testing.expectf(t, p.ret_value == nil, "ret_value should start nil")
	testing.expectf(t, p.type == .SOURCE, "type should be SOURCE")
	testing.expectf(t, p.parent == nil, "parent should be nil for root")
	testing.expectf(t, p.stats != nil, "root should allocate fresh stats")
	testing.expectf(t, p.stats.start_time != nil, "root should init start_time")
	testing.expectf(t, p.args == nil, "root should have no args")
	prgm_teardown(p)
}

@(test)
create_with_parent_inherits :: proc(t: ^testing.T) {
	parent, _ := create(nil)
	child, code := create(parent)
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, child != nil, "create should return a program")
	testing.expectf(t, child.parent == parent, "parent should be set")
	testing.expectf(t, child.args == parent.args, "child should inherit args")
	testing.expectf(t, child.stats == parent.stats, "child should share stats")
	prgm_teardown(child)
	prgm_teardown(parent)
}

@(test)
add_appends_statement :: proc(t: ^testing.T) {
	p, _ := create(nil)
	s, _ := syntax.create()
	code := add(p, s)
	testing.expectf(t, code == .OK, "add failed: %v", code)
	testing.expectf(t, p.length == 1, "length should be 1, got %d", p.length)
	testing.expectf(t, len(p.statements) == 1, "statements should hold 1")
	testing.expectf(t, p.statements[0] == s, "statements[0] should be the added syntax")
	prgm_teardown(p)
}

@(test)
add_multiple :: proc(t: ^testing.T) {
	p, _ := create(nil)
	for i in 0 ..< 3 {
		s, _ := syntax.create()
		add(p, s)
	}
	testing.expectf(t, p.length == 3, "length should be 3, got %d", p.length)
	testing.expectf(t, len(p.statements) == 3, "statements should hold 3")
	prgm_teardown(p)
}

@(test)
add_nil_program_errors :: proc(t: ^testing.T) {
	s, _ := syntax.create()
	code := add(nil, s)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PROGRAM_ADD, "add(nil, s) wrong code: %v", code)
}