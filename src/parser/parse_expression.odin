package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

primary_expression :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, .OBJECT_IS_NIL_IN_PARSER_PRIMARY_EXPRESSION
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token == nil do return
	if curr_token.type == .END_OF_FILE do return
	#partial switch (curr_token.type) {
	case .LEFT_BRACKET:
		return array_declaration(tokens)
	case .IDENTIFIER:
		return parse_identifier(tokens)
	case .LENGTH:
		return parse_len(tokens)
	case .STRING:
		return parse_string(tokens)
	case .HTTP:
		return parse_http(tokens)
	case .TIME:
		return parse_time(tokens)
	case .TERMINAL:
		return parse_terminal(tokens)
	case .EXISTS:
		return parse_exists(tokens)
	case .IN:
		return parse_in(tokens)
	case .KEY:
		return parse_key(tokens)
	case .JSON:
		return parse_json(tokens)
	case .EXECUTE:
		return parse_execute(tokens)
	case .STRING_WRAPPER, .NUMBER, .FALSE, .TRUE, .NULL, .AT:
		sntx = syntax.create() or_return
		sntx.token = curr_token
		token_list.advance(tokens) or_return
		return
	case .LEFT_PAREN:
		token_list.advance(tokens) or_return
		sntx = expression(tokens) or_return
		next_token := token_list.peek(tokens, 0) or_return
		if next_token == nil || next_token.type != .RIGHT_PAREN {
			return nil, .UNCLOSED_PARENTHESIS_IN_PARSE_PRIMARY_EXPRESSION
		}
		token_list.advance(tokens) or_return
		return
	case:
		return
	}
}

file_operation :: proc(
	tokens: ^types.token_list_t,
) -> (
	left: ^types.syntax_t,
	code: types.exit_codes,
) {
	left = primary_expression(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil && (curr_token.type == .RIGHT_ARROW || curr_token.type == .LEFT_ARROW) {
		op, alloc_err := syntax.create()
		if sys.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = primary_expression(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

string_operations :: proc(
	tokens: ^types.token_list_t,
) -> (
	left: ^types.syntax_t,
	code: types.exit_codes,
) {
	left = file_operation(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil && (curr_token.type == .COLON || curr_token.type == .COLON_HAT) {
		op := syntax.create() or_return
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = file_operation(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

unary :: proc(tokens: ^types.token_list_t) -> (op: ^types.syntax_t, code: types.exit_codes) {
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token != nil && (curr_token.type == .BANG || curr_token.type == .MINUS) {
		op = syntax.create() or_return
		op.token = curr_token
		token_list.advance(tokens) or_return
		op.left = unary(tokens) or_return
		return
	}
	op = string_operations(tokens) or_return
	return
}

multiplicitive :: proc(
	tokens: ^types.token_list_t,
) -> (
	left: ^types.syntax_t,
	code: types.exit_codes,
) {
	left = unary(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil &&
	    (curr_token.type == .STAR || curr_token.type == .SLASH || curr_token.type == .MODULUS) {
		op := syntax.create() or_return
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = unary(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

additive :: proc(tokens: ^types.token_list_t) -> (left: ^types.syntax_t, code: types.exit_codes) {
	left = multiplicitive(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil &&
	    (curr_token.type == .PLUS || curr_token.type == .MINUS || curr_token.type == .DOT_DOT) {
		op := syntax.create() or_return
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = multiplicitive(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

comparision :: proc(
	tokens: ^types.token_list_t,
) -> (
	left: ^types.syntax_t,
	code: types.exit_codes,
) {
	left = additive(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil &&
	    (curr_token.type == .GREATER_EQUAL ||
			    curr_token.type == .LESS_EQUAL ||
			    curr_token.type == .GREATER ||
			    curr_token.type == .LESS) {
		op, alloc_err := syntax.create()
		if sys.is_error(alloc_err) {
			return nil, alloc_err
		}
		op.token = curr_token
		op.left = left
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		op.right = additive(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

equality :: proc(tokens: ^types.token_list_t) -> (left: ^types.syntax_t, code: types.exit_codes) {
	left = comparision(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil && (curr_token.type == .EQUAL_EQUAL || curr_token.type == .BANG_EQUAL) {
		op := syntax.create() or_return
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = comparision(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

and_or :: proc(tokens: ^types.token_list_t) -> (left: ^types.syntax_t, code: types.exit_codes) {
	left = equality(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	for curr_token != nil && (curr_token.type == .AND || curr_token.type == .OR) {
		op := syntax.create() or_return
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = equality(tokens) or_return
		left = op
		curr_token = token_list.peek(tokens, 0) or_return
	}
	return
}

assignment :: proc(
	tokens: ^types.token_list_t,
) -> (
	left: ^types.syntax_t,
	code: types.exit_codes,
) {
	left = and_or(tokens) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token != nil &&
	   (curr_token.type == .EQUAL ||
			   curr_token.type == .PLUS_EQUAL ||
			   curr_token.type == .MINUS_EQUAL ||
			   curr_token.type == .STAR_EQUAL ||
			   curr_token.type == .SLASH_EQUAL) {
		op := syntax.create() or_return
		op.token = curr_token
		op.left = left
		token_list.advance(tokens) or_return
		op.right = assignment(tokens) or_return
		return op, .OK
	}
	return
}

expression :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = assignment(tokens) or_return
	return
}

statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, .OBJECT_IS_NIL_IN_PARSE_STATEMENT
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token == nil do return nil, .OK
	#partial switch (curr_token.type) {
	case .FUNCTION:
		return parse_function(tokens, parent)
	case .FOR:
		return parse_for(tokens, parent)
	case .IF:
		return parse_if(tokens, parent)
	case .PRINT:
		return parse_print(tokens)
	case .RETURN:
		return parse_return(tokens)
	case .VAR, .CONST:
		return variable_declaration(tokens)
	case .GLOBAL:
		return parse_global(tokens)
	case .PRINT_LINE:
		return parse_println(tokens)
	case .CONTINUE:
		return parse_continue(tokens)
	case .BREAK:
		return parse_break(tokens)
	case .OUT:
		return parse_out(tokens)
	case .CLEAR:
		return parse_clear(tokens)
	case .SLEEP:
		return parse_sleep(tokens)
	case .ERROR:
		return parse_error(tokens)
	case .REMOVE:
		return variable_remove(tokens)
	case .RM:
		return parse_rm(tokens)
	case:
		return expression(tokens)
	}
}
