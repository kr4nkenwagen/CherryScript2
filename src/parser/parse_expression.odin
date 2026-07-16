package parser

import "../syntax"
import "../token_list"
import "../types"

primary_expression :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	if tokens == nil {
		return nil, true
	}
	curr_token := token_list.peek(tokens, 0)
	synt, err := syntax.create()
	if err {
		return nil, true
	}
	switch (curr_token.type) {
	case .RIGHT_PAREN:
		free(synt)
		return nil, true
	case .LEFT_BRACKET:
		free(synt)
		return array_declaration(tokens)
	case .IDENTIFIER:
		return identifier(tokens)
	case .STRING_WRAPPER:
		fallthrough
	case .NUMBER:
		fallthrough
	case .FALSE:
		fallthrough
	case .TRUE:
		fallthrough
	case .NIL:
		synt.token = curr_token
		token_list.advance(tokens)
		return nil, true
	case .LEFT_PAREN:
		tkn := token_list.advance(tokens)
		if tkn == nil {
			//ERROR end of tokens
			return nil, true
		}
		synt, _ = expression(tokens)
		next_token := token_list.peek(tokens, 0)
		if next_token == nil || next_token.type != types.token_type_t.RIGHT_PAREN {
			//ERROR unexpected syntax
		}
		token_list.advance(tokens)
		return synt, false
	case .RIGHT_BRACE:
		fallthrough
	case .SOFT_TERMINATOR:
		fallthrough
	case .TERMINATOR:
		free(synt)
		return nil, true
	case .LEFT_BRACE:
		fallthrough
	case .COMMA:
		fallthrough
	case .DOT:
		fallthrough
	case .MINUS:
		fallthrough
	case .PLUS:
		fallthrough
	case .SEMICOLON:
		fallthrough
	case .SLASH:
		fallthrough
	case .STAR:
		fallthrough
	case .BANG:
		fallthrough
	case .EQUAL:
		fallthrough
	case .GREATER:
		fallthrough
	case .LESS:
		fallthrough
	case .COMMENT:
		fallthrough
	case .MODULUS:
		fallthrough
	case .COLON:
		fallthrough
	case .BANG_EQUAL:
		fallthrough
	case .GREATER_EQUAL:
		fallthrough
	case .LESS_EQUAL:
		fallthrough
	case .EQUAL_EQUAL:
		fallthrough
	case .COLON_HAT:
		fallthrough
	case .DOT_DOT:
		fallthrough
	case .AND:
		fallthrough
	case .CLASS:
		fallthrough
	case .ELSE:
		fallthrough
	case .FUNCTION:
		fallthrough
	case .FOR:
		fallthrough
	case .IF:
		fallthrough
	case .OR:
		fallthrough
	case .PRINT:
		fallthrough
	case .RETURN:
		fallthrough
	case .SUPER:
		fallthrough
	case .THIS:
		fallthrough
	case .VAR:
		fallthrough
	case .WHILE:
		fallthrough
	case .END_OF_FILE:
		fallthrough
	case .CONST:
		fallthrough
	case .RIGHT_BRACKET:
		fallthrough
	case .ELSE_IF:
		fallthrough
	case .PLUS_EQUAL:
		fallthrough
	case .MINUS_EQUAL:
		fallthrough
	case .STAR_EQUAL:
		fallthrough
	case .SLASH_EQUAL:
		fallthrough
	case .PRINT_LINE:
		fallthrough
	case .CONTINUE:
		fallthrough
	case .BREAK:
		fallthrough
	case .IMPORT:
		fallthrough
	case .OUT:
		fallthrough
	case .ERROR:
		fallthrough
	case .REMOVE:
		fallthrough
	case .UNKNOWN_TOKEN:
		break
	}
	free(synt)
	return nil, true
}

string_operations :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := primary_expression(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == types.token_type_t.COLON ||
			    curr_token.type == types.token_type_t.COLON_HAT) {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = primary_expression(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

unary :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := string_operations(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil && curr_token.type == types.token_type_t.BANG {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = string_operations(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

multiplicitive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := unary(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == types.token_type_t.STAR ||
			    curr_token.type == types.token_type_t.SLASH ||
			    curr_token.type == types.token_type_t.MODULUS) {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = unary(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

additive :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := multiplicitive(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == types.token_type_t.PLUS ||
			    curr_token.type == types.token_type_t.MINUS ||
			    curr_token.type == types.token_type_t.DOT_DOT) {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = multiplicitive(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}


comparision :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := additive(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == types.token_type_t.GREATER_EQUAL ||
			    curr_token.type == types.token_type_t.LESS_EQUAL ||
			    curr_token.type == types.token_type_t.GREATER ||
			    curr_token.type == types.token_type_t.LESS) {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = additive(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

equality :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := comparision(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == types.token_type_t.EQUAL_EQUAL ||
			    curr_token.type == types.token_type_t.BANG_EQUAL) {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = comparision(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
	}
	return left, false
}

assignment :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	left, _ := equality(tokens)
	curr_token := token_list.peek(tokens, 0)
	for curr_token != nil &&
	    (curr_token.type == types.token_type_t.EQUAL ||
			    curr_token.type == types.token_type_t.PLUS_EQUAL ||
			    curr_token.type == types.token_type_t.MINUS_EQUAL ||
			    curr_token.type == types.token_type_t.STAR_EQUAL ||
			    curr_token.type == types.token_type_t.SLASH_EQUAL) {
		op, err := syntax.create()
		if err {
			free(op)
			//ERROR end of tokens
			return nil, true
		}
		op.token = curr_token
		op.left = left
		token_list.advance(tokens)
		op.right, _ = equality(tokens)
		left = op
		curr_token = token_list.peek(tokens, 0)
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
	#partial switch (token_list.peek(tokens, 0).type) {
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
	case .VAR:
		fallthrough
	case .CONST:
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
