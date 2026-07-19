package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

if_statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	types.exit_codes,
) {
	syntax_parent, parent_err := syntax.create()
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	syntax_parent.token, parent_err = token_list.peek(tokens, 0)
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	syntax_parent.value, parent_err = expression(tokens)
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token.type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens)
		curr_token, curr_token_err = token_list.peek(tokens, 0)
	}
	if curr_token.type == types.token_type_t.LEFT_BRACE {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	syntax_parent.branch, parent_err = branch(tokens, parent)
	if sys.is_error(parent_err) {
		return nil, parent_err
	}
	syntax_parent.branch.type = types.program_type_t.IF
	curr_syntax := syntax_parent
	curr_token, curr_token_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token.type == types.token_type_t.ELSE_IF {
		curr_syntax_err: types.exit_codes
		curr_syntax.right, curr_syntax_err = syntax.create()
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.right.token = curr_token
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		curr_syntax.right.value, curr_syntax_err = expression(tokens)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.right.branch, curr_syntax_err = branch(tokens, parent)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.branch.type = types.program_type_t.IF
		curr_syntax = curr_syntax.right
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	if curr_token.type == types.token_type_t.ELSE {
		curr_syntax_err: types.exit_codes
		curr_syntax.right, curr_syntax_err = syntax.create()
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.right.token = curr_token
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		curr_syntax.right.branch, curr_syntax_err = branch(tokens, parent)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		curr_syntax.branch.type = types.program_type_t.IF
	}
	return syntax_parent, types.exit_codes.OK
}

while :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	types.exit_codes,
) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.value, curr_syntax_err = expression(tokens)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.branch, curr_syntax_err = branch(tokens, parent)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.branch.type = types.program_type_t.LOOP
	return curr_syntax, types.exit_codes.OK
}

for_statement :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	types.exit_codes,
) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	adv, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	if adv.type != types.token_type_t.LEFT_PAREN {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	_, adv_err = token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.left, curr_syntax_err = line(tokens, parent)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.value, curr_syntax_err = line(tokens, parent)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.right, curr_syntax_err = line(tokens, parent)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err = token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.branch, curr_syntax_err = branch(tokens, parent)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.branch.type = types.program_type_t.LOOP
	return curr_syntax, types.exit_codes.OK
}

return_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.value, curr_syntax_err = expression(tokens)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	return curr_syntax, types.exit_codes.OK
}

continue_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	return curr_syntax, types.exit_codes.OK
}

break_statement :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, arg_err := token_list.advance(tokens)
	if sys.is_error(arg_err) {
		return nil, arg_err
	}
	return curr_syntax, types.exit_codes.OK
}

error :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.value, curr_syntax_err = expression(tokens)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	return curr_syntax, types.exit_codes.OK
}

out :: proc(tokens: ^types.token_list_t) -> (^types.syntax_t, types.exit_codes) {
	curr_syntax, curr_syntax_err := syntax.create()
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.token, curr_syntax_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	curr_syntax.value, curr_syntax_err = expression(tokens)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	return curr_syntax, types.exit_codes.OK
}
