package parser

import "../syntax"
import "../token_list"
import "../types"

parse_base_identifier :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token.type != .IDENTIFIER do return nil, nil, .EXPECTED_IDENTIFIER_IN_PARSE_BASE_IDENTIFIER
	node := syntax.create() or_return
	node.token = curr_token
	next_token := token_list.advance(tokens) or_return
	return node, next_token, .OK
}

parse_member_access :: proc(
	tokens: ^types.token_list_t,
	curr_syntax: ^types.syntax_t,
) -> (
	sntx: ^types.syntax_t,
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	next_token := token_list.peek(tokens, 1) or_return
	if next_token.type != .IDENTIFIER do return nil, {}, .EXPECTED_IDENTIFIER_IN_PARSE_MEMBER_ACCESS
	member_token := token_list.advance(tokens) or_return
	member_node := syntax.create() or_return
	member_node.token = member_token
	curr_syntax.value = member_node
	following_token := token_list.advance(tokens) or_return
	return member_node, following_token, .OK
}

parse_index_access :: proc(
	tokens: ^types.token_list_t,
	curr_syntax: ^types.syntax_t,
) -> (
	sntx: ^types.syntax_t,
	tkn: ^types.token_t,
	code: types.exit_codes,
) {
	token_list.advance(tokens) or_return
	expr_node := expression(tokens) or_return
	curr_syntax.value = expr_node
	following_token := token_list.advance(tokens) or_return
	return expr_node, following_token, .OK
}

parse_identifier :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	codes: types.exit_codes,
) {
	root_syntax, curr_token := parse_base_identifier(tokens) or_return
	curr_syntax := root_syntax
	postfix_loop: for {
		#partial switch curr_token.type {
		case .DOT:
			next_node, next_tok := parse_member_access(tokens, curr_syntax) or_return
			curr_syntax = next_node
			curr_token = next_tok
		case .LEFT_BRACKET:
			next_node, next_tok := parse_index_access(tokens, curr_syntax) or_return
			curr_syntax = next_node
			curr_token = next_tok
		case:
			break postfix_loop
		}
	}
	if curr_token.type == .LEFT_PAREN {
		args_node := passed_function_args(tokens) or_return
		root_syntax.left = args_node
	}
	return root_syntax, .OK
}
