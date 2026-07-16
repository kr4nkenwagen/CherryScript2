package parser

import "../syntax"
import "../token_list"
import "../types"

if_statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	bool,
) {
	syntax_parent, _ := syntax.create()
	syntax_parent.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	syntax_parent.value, _ = expression(tokens)
	for token_list.peek(tokens, 0).type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens)
	}
	if token_list.peek(tokens, 0).type == types.token_type_t.LEFT_BRACE {
		//ERROR unexpected syntax
		return nil, true
	}
	syntax_parent.branch, _ = branch(tokens, parent)
	syntax_parent.branch.type = types.program_type_t.IF
	curr_syntax := syntax_parent
	for token_list.peek(tokens, 0).type == types.token_type_t.ELSE_IF {
		curr_syntax.right, _ = syntax.create()
		curr_syntax.right.token = token_list.peek(tokens, 0)
		token_list.advance(tokens)
		curr_syntax.right.value, _ = expression(tokens)
		curr_syntax.right.branch, _ = branch(tokens, parent)
		curr_syntax.branch.type = types.program_type_t.IF
		curr_syntax = curr_syntax.right
	}
	if token_list.peek(tokens, 0).type == types.token_type_t.ELSE {
		curr_syntax.right, _ = syntax.create()
		curr_syntax.right.token = token_list.peek(tokens, 0)
		token_list.advance(tokens)
		curr_syntax.right.branch, _ = branch(tokens, parent)
		curr_syntax.branch.type = types.program_type_t.IF
	}
	return syntax_parent, false
}

while :: proc(tokens: ^types.token_list_t, parent: ^types.program_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	curr_syntax.value, _ = expression(tokens)
	curr_syntax.branch, _ = branch(tokens, parent)
	curr_syntax.branch.type = types.program_type_t.LOOP
	return curr_syntax, false
}

for_statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	bool,
) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	if token_list.advance(tokens).type != types.token_type_t.LEFT_PAREN {
		//ERROR unexpected syntax
		return nil, true
	}
	token_list.advance(tokens)
	curr_syntax.left, _ = line(tokens, parent)
	curr_syntax.value, _ = line(tokens, parent)
	curr_syntax.right, _ = line(tokens, parent)
	token_list.advance(tokens)
	curr_syntax.branch, _ = branch(tokens, parent)
	curr_syntax.branch.type = types.program_type_t.LOOP
	return curr_syntax, false
}

return_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	curr_syntax.value, _ = expression(tokens)
	return curr_syntax, false
}

continue_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	return curr_syntax, false
}

break_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	return curr_syntax, false
}

error :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	curr_syntax.value, _ = expression(tokens)
	return curr_syntax, false
}

out :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	curr_syntax.value, _ = expression(tokens)
	return curr_syntax, false
}
