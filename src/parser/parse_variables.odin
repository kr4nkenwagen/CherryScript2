package parser

import "../syntax"
import "../token"
import "../token_list"
import "../types"


variable_declaration :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	if tokens == nil {
		return nil, true
	}
	declaration, _ := syntax.create()
	declaration.token = token_list.peek(tokens, 0)
	curr_token := token_list.advance(tokens)
	prev_syntax := declaration
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token = token_list.advance(tokens)
		}
		if curr_token.type != types.token_type_t.IDENTIFIER {
			//ERROR unexpected syntax
			return nil, true
		}
		curr_syntax, _ := syntax.create()
		curr_syntax.token = curr_token
		if token_list.advance(tokens).type == types.token_type_t.EQUAL {
			token_list.advance(tokens)
			curr_syntax.value, _ = expression(tokens)
		} else {
			if declaration.token.type == types.token_type_t.CONST {
				//ERROR unassigned const
				return nil, true
			}
			curr_syntax.value, _ = syntax.create()
			curr_syntax.value.token = token.create(nil, types.token_type_t.NIL, "null")
		}
		curr_token = token_list.peek(tokens, 0)
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	return declaration, false
}

variable_remove :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	declaration, _ := syntax.create()
	declaration.token = token_list.peek(tokens, 0)
	curr_token := token_list.advance(tokens)
	prev_syntax := declaration
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token = token_list.advance(tokens)
		}
		if curr_token.type != types.token_type_t.IDENTIFIER {
			//ERROR unexpected syntax
			return nil, true
		}
		curr_syntax, _ := syntax.create()
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token = token_list.advance(tokens)
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	return declaration, false
}

array_declaration :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	declaration, err := syntax.create()
	if err {
		return nil, true
	}
	declaration.token = token_list.peek(tokens, 0)
	curr_token := token_list.advance(tokens)
	prev_syntax := declaration
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token = token_list.advance(tokens)
		}
		if !(curr_token.type == types.token_type_t.IDENTIFIER ||
			   curr_token.type == types.token_type_t.NUMBER ||
			   curr_token.type == types.token_type_t.STRING_WRAPPER) {
			//ERROR expected identifier or literal
			return nil, true
		}
		curr_syntax, _ := syntax.create()
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token = token_list.advance(tokens)
		if curr_token.type != token.type_t.COMMA {
			break
		}
	}
	if curr_token.type != token.type_t.RIGHT_BRACKET {
		//ERROR bracket not closed
		return nil, true
	}
	token_list.advance(tokens)
	return declaration, false
}

identifier :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	curr_syntax, _ := syntax.create()
	curr_syntax.token = token_list.peek(tokens, 0)
	if curr_syntax.token.type != token.type_t.IDENTIFIER {
		return nil, true
	}
	token_list.advance(tokens)
	if token_list.peek(tokens, 0).type == token.type_t.LEFT_BRACKET {
		curr_syntax.right, _ = array_declaration(tokens)
	}
	if token_list.peek(tokens, 0).type == token.type_t.LEFT_PAREN {
		curr_syntax.left, _ = passed_function_args(tokens)
	}
	return curr_syntax, false
}
