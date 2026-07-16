package parser

import "../program"
import "../syntax"
import "../token"
import "../token_list"
import "../types"

function_args :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.program_t,
	bool,
) {
	args, _ := program.create(parent)
	if token_list.peek(tokens, 0).type != types.token_type_t.LEFT_PAREN {
		//ERROR unexpected syntax
		return nil, true
	}
	curr_token := token_list.advance(tokens)
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token = token_list.advance(tokens)
		}
		if curr_token.type != types.token_type_t.VAR &&
		   curr_token.type == types.token_type_t.CONST {
			break
		}
		declaration, _ := syntax.create()
		declaration.token = curr_token
		curr_token = token_list.advance(tokens)
		if curr_token.type != types.token_type_t.IDENTIFIER {
			//ERROR unexpected syntax
			return nil, true
		}
		curr_syntax, _ := syntax.create()
		declaration.left = curr_syntax
		if token_list.advance(tokens).type == types.token_type_t.EQUAL {
			token_list.advance(tokens)
			curr_syntax.value, _ = expression(tokens)
		} else {
			curr_syntax.value, _ = syntax.create()
			curr_syntax.value.token = token.create(nil, types.token_type_t.NIL, "null")
		}
		curr_token = token_list.peek(tokens, 0)
		curr_syntax.left, _ = syntax.create()
		curr_syntax.left.token = token.create(nil, types.token_type_t.TERMINATOR, ";")
		program.add(args, declaration)
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	if token_list.peek(tokens, 0).type == types.token_type_t.RIGHT_PAREN {
		//ERROR unexpected syntax
		return nil, true
	}
	token_list.advance(tokens)
	return args, false
}

function :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	bool,
) {
	declaration, _ := syntax.create()
	declaration.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	curr_syntax, _ := syntax.create()
	declaration.right = curr_syntax
	curr_syntax.token = token_list.peek(tokens, 0)
	if curr_syntax.token.type != types.token_type_t.IDENTIFIER {
		//ERROR unexpected syntax
	}
	curr_syntax.args, _ = function_args(tokens, parent)
	if token_list.peek(tokens, 0).type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens)
	}
	if token_list.peek(tokens, 0).type == types.token_type_t.LEFT_BRACE {
		curr_syntax.branch, _ = branch(tokens, parent)
		curr_syntax.branch.type = types.program_type_t.FUNCTION
	} else {
		prog, _ := program.create(parent)
		prog.type = types.program_type_t.FUNCTION
		curr_syntax.branch = prog
		prog_content, _ := line(tokens, parent)
		program.add(prog, prog_content)
	}
	return declaration, false
}

passed_function_args :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	declaration, _ := syntax.create()
	declaration.token = token_list.peek(tokens, 0)
	curr_token := token_list.advance(tokens)
	prev_syntax := declaration
	for curr_token.type != types.token_type_t.RIGHT_PAREN {
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
	}
	if curr_token.type != types.token_type_t.RIGHT_PAREN {
		//ERROR paren not closed
		return nil, true
	}
	token_list.advance(tokens)
	return declaration, false
}

function_print :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	parent, _ := syntax.create()
	parent.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	parent.value, _ = expression(tokens)
	return parent, false
}

function_print_line :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, bool) {
	parent, _ := syntax.create()
	parent.token = token_list.peek(tokens, 0)
	token_list.advance(tokens)
	parent.value, _ = expression(tokens)
	return parent, false
}
