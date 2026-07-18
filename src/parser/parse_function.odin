package parser

import "../error"
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
	types.exit_codes,
) {
	args, _ := program.create(parent)
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token.type != types.token_type_t.LEFT_PAREN {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	curr_token, curr_token_err = token_list.advance(tokens)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token, curr_token_err = token_list.advance(tokens)
			if error.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		if curr_token.type != types.token_type_t.VAR &&
		   curr_token.type == types.token_type_t.CONST {
			break
		}
		declaration, declaration_err := syntax.create()
		if error.is_error(declaration_err) {
			return nil, declaration_err
		}
		declaration.token = curr_token
		curr_token, curr_token_err = token_list.advance(tokens)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		if curr_token.type != types.token_type_t.IDENTIFIER {
			return nil, types.exit_codes.UNEXPECTED_SYNTAX
		}
		curr_syntax, curr_syntax_err := syntax.create()
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		declaration.left = curr_syntax
		eq_token, eq_token_err := token_list.advance(tokens)
		if error.is_error(eq_token_err) {
			return nil, eq_token_err
		}
		if eq_token.type == types.token_type_t.EQUAL {
			_, adv_err := token_list.advance(tokens)
			if error.is_error(adv_err) {
				return nil, adv_err
			}
			curr_syntax.value, _ = expression(tokens)
		} else {
			curr_syntax.value, curr_syntax_err = syntax.create()
			if error.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
			curr_syntax.value.token, curr_token_err = token.create(
				nil,
				types.token_type_t.NIL,
				"null",
			)
			if error.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		curr_syntax.left, _ = syntax.create()
		curr_syntax.left.token, curr_token_err = token.create(
			nil,
			types.token_type_t.TERMINATOR,
			";",
		)
		if error.is_error(curr_token_err) {
			return nil, curr_token_err
		}
		program.add(args, declaration)
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	curr_token, curr_token_err = token_list.peek(tokens, 0)
	if curr_token.type == types.token_type_t.RIGHT_PAREN {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	_, adv_err := token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	return args, types.exit_codes.OK
}

function :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	types.exit_codes,
) {
	declaration, declaration_err := syntax.create()
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	declaration.token, declaration_err = token_list.peek(tokens, 0)
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	_, adv_err := token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax, curr_syntax_err := syntax.create()
	if error.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	declaration.right = curr_syntax
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if error.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	if curr_syntax.token.type != types.token_type_t.IDENTIFIER {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	curr_syntax.args, _ = function_args(tokens, parent)
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token.type == types.token_type_t.TERMINATOR {
		_, adv_err := token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
	}
	curr_token, curr_token_err = token_list.peek(tokens, 0)
	if error.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token.type == types.token_type_t.LEFT_BRACE {
		curr_syntax.branch, branch_err = branch(tokens, parent)
		if error.is_error(branch_err) {
			return nil, branch_err
		}
		curr_syntax.branch.type = types.program_type_t.FUNCTION
	} else {
		prog, prog_err := program.create(parent)
		if error.is_error(prog_err) {
			return nil, prog_err
		}
		prog.type = types.program_type_t.FUNCTION
		curr_syntax.branch = prog
		prog_content, prog_content_err := line(tokens, parent)
		if error.is_error(prog_content_err) {
			return nil, prog_content_err
		}
		program.add(prog, prog_content)
	}
	return declaration, types.exit_codes.OK
}

passed_function_args :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	declaration, declaration_err := syntax.create()
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	declaration.token, declaration_err = token_list.peek(tokens, 0)
	if error.is_error(declaration_err) {
		return nil, declaration_err
	}
	curr_token, adv_err := token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	prev_syntax := declaration
	for curr_token.type != types.token_type_t.RIGHT_PAREN {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token, adv_err = token_list.advance(tokens)
			if error.is_error(adv_err) {
				return nil, adv_err
			}
		}
		if !(curr_token.type == types.token_type_t.IDENTIFIER ||
			   curr_token.type == types.token_type_t.NUMBER ||
			   curr_token.type == types.token_type_t.STRING_WRAPPER) {
			return nil, types.exit_codes.EXPECTED_IDENTIFIER_OR_LITERAL
		}
		curr_syntax, curr_syntax_err := syntax.create()
		if error.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.token = curr_token
		prev_syntax.left = curr_syntax
		prev_syntax = curr_syntax
		curr_token, adv_err = token_list.advance(tokens)
		if error.is_error(adv_err) {
			return nil, adv_err
		}
	}
	if curr_token.type != types.token_type_t.RIGHT_PAREN {
		return nil, types.exit_codes.UNCLOSED_PARENTHESIS
	}
	_, adv_err = token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	return declaration, types.exit_codes.OK
}

function_print :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	parent, parent_err := syntax.create()
	if error.is_error(parent_err) {
		return nil, parent_err
	}
	parent.token, parent_err = token_list.peek(tokens, 0)
	if error.is_error(parent_err) {
		return nil, parent_err
	}
	_, adv_err := token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	parent.value, parent_err = expression(tokens)
	if error.is_error(parent_err) {
		return nil, parent_err
	}
	return parent, types.exit_codes.OK
}

function_print_line :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	parent, parent_err := syntax.create()
	if error.is_error(parent_err) {
		return nil, parent_err
	}
	parent.token, parent_err = token_list.peek(tokens, 0)
	if error.is_error(parent_err) {
		return nil, parent_err
	}
	_, adv_err := token_list.advance(tokens)
	if error.is_error(adv_err) {
		return nil, adv_err
	}
	parent.value, parent_err = expression(tokens)
	if error.is_error(parent_err) {
		return nil, parent_err
	}
	return parent, types.exit_codes.OK
}
