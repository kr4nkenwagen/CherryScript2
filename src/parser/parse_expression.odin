package parser

import "../syntax"
import "../token_list"
import "../types"

primary_expression :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	if tokens == nil {
		return nil, true
	}
	curr_token := token_list.peek(tokens, 0)
	if curr_token == nil {
		return nil, true
	}

	#partial switch (curr_token.type) {
	case .LEFT_BRACKET:
		return array_declaration(tokens)
	case .IDENTIFIER:
		return identifier(tokens)
	case .STRING_WRAPPER, .NUMBER, .FALSE, .TRUE, .NIL:
		synt, err := syntax.create()
		if err {
			return nil, true
		}
		synt.token = curr_token
		token_list.advance(tokens)
		return synt, false

	case .LEFT_PAREN:
		token_list.advance(tokens) // Consume '('
		synt, err := expression(tokens)
		if err {
			return nil, true
		}

		next_token := token_list.peek(tokens, 0)
		if next_token == nil || next_token.type != .RIGHT_PAREN {
			// ERROR: Unclosed parenthesis
			return nil, true
		}
		token_list.advance(tokens)
		return synt, false

	case:
		return nil, true
	}
}

string_operations :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, err := primary_expression(tokens)
	if err do return nil, true

	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil && (curr_token.type == .COLON || curr_token.type == .COLON_HAT) {
		op, alloc_err := syntax.create()
		if alloc_err {
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)

		op.right, err = primary_expression(tokens)
		if err {
			free(op)
			return nil, true
		}
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

unary :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_token := token_list.peek(tokens, 0)
	if curr_token == nil do return nil, true
	if curr_token.type == .BANG || curr_token.type == .MINUS {
		op, err := syntax.create()
		if err do return nil, true
		op.token = curr_token
		token_list.advance(tokens)
		op.left, err = unary(tokens)
		if err {
			free(op)
			return nil, true
		}
		return op, false
	}

	return string_operations(tokens)
}

multiplicitive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, err := unary(tokens)
	if err do return nil, true
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == .STAR || curr_token.type == .SLASH || curr_token.type == .MODULUS) {
		op, alloc_err := syntax.create()
		if alloc_err do return nil, true
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, err = unary(tokens)
		if err {
			free(op)
			return nil, true
		}
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

additive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, err := multiplicitive(tokens)
	if err do return nil, true
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == .PLUS || curr_token.type == .MINUS || curr_token.type == .DOT_DOT) {
		op, alloc_err := syntax.create()
		if alloc_err do return nil, true
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, err = multiplicitive(tokens)
		if err {
			free(op)
			return nil, true
		}
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

comparision :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, err := additive(tokens)
	if err do return nil, true
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == .GREATER_EQUAL ||
			    curr_token.type == .LESS_EQUAL ||
			    curr_token.type == .GREATER ||
			    curr_token.type == .LESS) {
		op, alloc_err := syntax.create()
		if alloc_err do return nil, true
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, err = additive(tokens)
		if err {
			free(op)
			return nil, true
		}
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

equality :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, err := comparision(tokens)
	if err do return nil, true
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil && (curr_token.type == .EQUAL_EQUAL || curr_token.type == .BANG_EQUAL) {
		op, alloc_err := syntax.create()
		if alloc_err do return nil, true
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, err = comparision(tokens)
		if err {
			free(op)
			return nil, true
		}
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

assignment :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, err := equality(tokens)
	if err do return nil, true
	curr_token := token_list.peek(tokens, 0)
	if curr_token != nil &&
	   (curr_token.type == .EQUAL ||
			   curr_token.type == .PLUS_EQUAL ||
			   curr_token.type == .MINUS_EQUAL ||
			   curr_token.type == .STAR_EQUAL ||
			   curr_token.type == .SLASH_EQUAL) {
		op, alloc_err := syntax.create()
		if alloc_err do return nil, true
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, err = assignment(tokens)
		if err {
			free(op)
			return nil, true
		}
		return op, false
	}
	return left, false
}

expression :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	return assignment(tokens)
}

statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	bool,
) {
	if tokens == nil {
		return nil, true
	}
	curr_token := token_list.peek(tokens, 0)
	if curr_token == nil do return nil, true

	#partial switch (curr_token.type) {
	case .FUNCTION:
		return function(tokens, parent)
	case .FOR:
		return for_statement(tokens, parent)
	case .IF:
		return if_statement(tokens, parent)
	case .PRINT:
		return function_print(tokens)
	case .RETURN:
		return return_statement(tokens)
	case .VAR, .CONST:
		return variable_declaration(tokens)
	case .WHILE:
		return while(tokens, parent)
	case .PRINT_LINE:
		return function_print_line(tokens)
	case .CONTINUE:
		return continue_statement(tokens)
	case .BREAK:
		return break_statement(tokens)
	case .OUT:
		return out(tokens)
	case .ERROR:
		return error(tokens)
	case .REMOVE:
		return variable_remove(tokens)
	case:
		return expression(tokens)
	}
}
