package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

primary_expression :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	if tokens == nil {
		return nil, .OBJECT_IS_NIL
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token == nil {
		return nil, .OK
	}
	if curr_token.type == .END_OF_FILE {
		return nil, .OK
	}
	#partial switch (curr_token.type) {
	case .LEFT_BRACKET:
		return array_declaration(tokens)
	case .IDENTIFIER:
		return parse_identifier(tokens)
	case .LENGTH:
		return parse_len(tokens)
	case .GET:
		return parse_get(tokens)
	case .TIME:
		return parse_time(tokens)
	case .EXISTS:
		return parse_exists(tokens)
	case .IN:
		return parse_in(tokens)
	case .KEY:
		return parse_key(tokens)
	case .JSON:
		return parse_json(tokens)
	case .STRING_WRAPPER, .NUMBER, .FALSE, .TRUE, .NULL, .AT:
		synt, err := syntax.create()
		if sys.is_error(err) {
			return nil, err
		}
		synt.token = curr_token
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		return synt, types.exit_codes.OK
	case .LEFT_PAREN:
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		synt, err := expression(tokens)
		if sys.is_error(err) {
			return nil, err
		}
		next_token, next_token_err := token_list.peek(tokens, 0)
		if sys.is_error(next_token_err) {
			return nil, next_token_err
		}
		if next_token == nil || next_token.type != .RIGHT_PAREN {
			return nil, .UNCLOSED_PARENTHESIS
		}
		_, adv_err = token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		return synt, .OK
	case:
		return nil, .OK
	}
}

file_operation :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := primary_expression(tokens)
	if sys.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil && (curr_token.type == .RIGHT_ARROW || curr_token.type == .LEFT_ARROW) {
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
		op.right, err = primary_expression(tokens)
		if sys.is_error(err) {
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, .OK
}

string_operations :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := file_operation(tokens)
	if sys.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil && (curr_token.type == .COLON || curr_token.type == .COLON_HAT) {
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
		op.right, err = file_operation(tokens)
		if sys.is_error(err) {
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, .OK
}

unary :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token != nil && (curr_token.type == .BANG || curr_token.type == .MINUS) {
		op, err := syntax.create()
		if sys.is_error(err) {
			return nil, err
		}
		op.token = curr_token
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		op.left, err = unary(tokens)
		if sys.is_error(err) {
			return nil, err
		}
		return op, .OK
	}
	return string_operations(tokens)
}

multiplicitive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	left, err := unary(tokens)
	if sys.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil &&
	    (curr_token.type == .STAR || curr_token.type == .SLASH || curr_token.type == .MODULUS) {
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
		op.right, err = unary(tokens)
		if sys.is_error(err) {
			return nil, err
		}
		left = op
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return left, .OK
}

additive :: proc(tokens: ^types.token_list_t) -> (sntx: ^types.syntax_t, code: types.exit_codes) {
	left := multiplicitive(tokens) or_return
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
	return left, .OK
}

comparision :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	left := additive(tokens) or_return
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
	return left, .OK
}

equality :: proc(tokens: ^types.token_list_t) -> (sntx: ^types.syntax_t, code: types.exit_codes) {
	left := comparision(tokens) or_return
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
	return left, .OK
}

and_or :: proc(tokens: ^types.token_list_t) -> (sntx: ^types.syntax_t, code: types.exit_codes) {
	left := equality(tokens) or_return
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
	return left, .OK
}

assignment :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	left := and_or(tokens) or_return
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
	return left, .OK
}

expression :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	return assignment(tokens)
}

statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, types.exit_codes.OBJECT_IS_NIL
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
	case .WHILE:
		return parse_while(tokens, parent)
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
