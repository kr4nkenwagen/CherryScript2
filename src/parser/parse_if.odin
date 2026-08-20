package parser

import "../syntax"
import "../token_list"
import "../types"

parse_if :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	syntax_parent := syntax.create() or_return
	syntax_parent.token = token_list.peek(tokens, 0) or_return
	token_list.advance(tokens) or_return
	syntax_parent.value = expression(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token.type == .TERMINATOR {
		token_list.advance(tokens) or_return
		curr_token = token_list.peek(tokens, 0) or_return
	}
	if curr_token.type != .LEFT_BRACE do return nil, .EXPECTED_LEFT_BRACE_IN_PARSE_IF
	syntax_parent.branch = branch(tokens, parent) or_return
	syntax_parent.branch.type = .IF
	curr_syntax := syntax_parent
	lookahead_idx := 0
	next_tok := token_list.peek(tokens, lookahead_idx) or_return
	for next_tok.type == .TERMINATOR {
		lookahead_idx += 1
		next_tok = token_list.peek(tokens, lookahead_idx) or_return
	}
	for next_tok.type == .ELSE_IF {
		// Consume intermediate terminators
		for i := 0; i < lookahead_idx; i += 1 {
			token_list.advance(tokens) or_return
		}
		curr_syntax.right = syntax.create() or_return
		curr_syntax.right.token = token_list.peek(tokens, 0) or_return
		token_list.advance(tokens) or_return
		curr_syntax.right.value = expression(tokens) or_return
		curr_syntax.right.branch = branch(tokens, parent) or_return
		curr_syntax.right.branch.type = .IF
		curr_syntax = curr_syntax.right
		lookahead_idx = 0
		next_tok = token_list.peek(tokens, lookahead_idx) or_return
		for next_tok.type == .TERMINATOR {
			lookahead_idx += 1
			next_tok = token_list.peek(tokens, lookahead_idx) or_return
		}
	}
	if next_tok.type == .ELSE {
		for i := 0; i < lookahead_idx; i += 1 {
			token_list.advance(tokens) or_return
		}
		curr_syntax.right = syntax.create() or_return
		curr_syntax.right.token = token_list.peek(tokens, 0) or_return
		token_list.advance(tokens) or_return
		curr_syntax.right.branch = branch(tokens, parent) or_return
		curr_syntax.right.branch.type = .IF
	}
	return syntax_parent, .OK
}
