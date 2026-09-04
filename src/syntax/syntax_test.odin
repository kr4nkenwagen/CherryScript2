package syntax

import "core:testing"
import "../types"

@(test)
create_returns_empty_syntax :: proc(t: ^testing.T) {
	s, code := create()
	testing.expectf(t, code == .OK, "create failed: %v", code)
	testing.expectf(t, s != nil, "create should return a syntax node")
	testing.expectf(t, s.token == nil, "token should default nil")
	testing.expectf(t, s.left == nil, "left should default nil")
	testing.expectf(t, s.right == nil, "right should default nil")
	testing.expectf(t, s.value == nil, "value should default nil")
	testing.expectf(t, s.branch == nil, "branch should default nil")
	testing.expectf(t, s.args == nil, "args should default nil")
	free(s)
}

@(test)
create_many_distinct :: proc(t: ^testing.T) {
	a, _ := create()
	b, _ := create()
	testing.expectf(t, a != b, "each create should return a distinct node")
	free(a)
	free(b)
}