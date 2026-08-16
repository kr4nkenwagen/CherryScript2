package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

// Parses the initial base identifier node and stores its token.
parse_base_identifier :: proc(
	tokens: ^types.token_list_t,
) -> (
	^types.syntax_t,
	^types.token_t,
	types.exit_codes,
) {
	curr_token, peek_err := token_list.peek(tokens, 0)
	if sys.is_error(peek_err) {
		return nil, nil, peek_err
	}

	if curr_token.type != .IDENTIFIER {
		return nil, nil, .EXPECTED_IDENTIFIER
	}

	node, create_err := syntax.create()
	if sys.is_error(create_err) {
		return nil, nil, create_err
	}

	node.token = curr_token

	next_token, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, nil, adv_err
	}

	return node, next_token, .OK
}

// Consumes `.DOT`, captures the following IDENTIFIER token into node.token, and advances.
parse_member_access :: proc(
	tokens: ^types.token_list_t,
	curr_syntax: ^types.syntax_t,
) -> (
	^types.syntax_t,
	^types.token_t,
	types.exit_codes,
) {
	next_token, peek_err := token_list.peek(tokens, 1)
	if sys.is_error(peek_err) {
		return nil, {}, peek_err
	}

	if next_token.type != .IDENTIFIER {
		return nil, {}, .UNEXPECTED_IDENTIFIER_OR_LITERAL
	}

	// Advance past DOT onto the IDENTIFIER token
	member_token, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, {}, adv_err
	}

	member_node, create_err := syntax.create()
	if sys.is_error(create_err) {
		return nil, {}, create_err
	}

	member_node.token = member_token
	curr_syntax.value = member_node

	// Advance past the IDENTIFIER token to get the next token (.DOT, [, etc.)
	following_token, adv_next_err := token_list.advance(tokens)
	if sys.is_error(adv_next_err) {
		return nil, {}, adv_next_err
	}

	return member_node, following_token, .OK
}

// Parses `[expression]` index access and advances past the closing bracket.
parse_index_access :: proc(
	tokens: ^types.token_list_t,
	curr_syntax: ^types.syntax_t,
) -> (
	^types.syntax_t,
	^types.token_t,
	types.exit_codes,
) {
	// Advance past LEFT_BRACKET into expression
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, {}, adv_err
	}

	expr_node, expr_err := expression(tokens)
	if sys.is_error(expr_err) {
		return nil, {}, expr_err
	}

	curr_syntax.value = expr_node

	// Advance past RIGHT_BRACKET to the next token
	following_token, adv_close_err := token_list.advance(tokens)
	if sys.is_error(adv_close_err) {
		return nil, {}, adv_close_err
	}

	return expr_node, following_token, .OK
}

// Main parser entry point handling nested member and index chains.
parse_identifier :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	root_syntax, curr_token, base_err := parse_base_identifier(tokens)
	if sys.is_error(base_err) {
		return nil, base_err
	}

	curr_syntax := root_syntax

	postfix_loop: for {
		#partial switch curr_token.type {
		case .DOT:
			next_node, next_tok, member_err := parse_member_access(tokens, curr_syntax)
			if sys.is_error(member_err) {
				return nil, member_err
			}
			curr_syntax = next_node
			curr_token = next_tok

		case .LEFT_BRACKET:
			next_node, next_tok, index_err := parse_index_access(tokens, curr_syntax)
			if sys.is_error(index_err) {
				return nil, index_err
			}
			curr_syntax = next_node
			curr_token = next_tok

		case:
			break postfix_loop
		}
	}

	if curr_token.type == .LEFT_PAREN {
		args_node, args_err := passed_function_args(tokens)
		if sys.is_error(args_err) {
			return nil, args_err
		}
		root_syntax.left = args_node
	}

	return root_syntax, .OK
}
