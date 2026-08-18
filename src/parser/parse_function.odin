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
	prgm: ^types.program_t,
	code: types.exit_codes,
) {
	args := program.create(parent) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token.type != types.token_type_t.LEFT_PAREN {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	curr_token = token_list.advance(tokens) or_return
	for {
		if curr_token.type == types.token_type_t.COMMA {
			curr_token = token_list.advance(tokens) or_return
		}
		if curr_token.type != types.token_type_t.VAR &&
		   curr_token.type != types.token_type_t.CONST {
			break
		}
		declaration := syntax.create() or_return
		declaration.token = curr_token
		curr_token = token_list.advance(tokens) or_return
		if curr_token.type != types.token_type_t.IDENTIFIER {
			return nil, types.exit_codes.UNEXPECTED_SYNTAX
		}
		curr_syntax := syntax.create() or_return
		curr_syntax.token = curr_token
		declaration.left = curr_syntax
		eq_token := token_list.advance(tokens) or_return

		if eq_token.type == types.token_type_t.EQUAL {
			token_list.advance(tokens) or_return
			curr_syntax.value, _ = expression(tokens)
		} else {

			curr_syntax.value = syntax.create() or_return
			if curr_syntax.value.token == nil {
			}
			curr_syntax.value.token = token.create(nil, types.token_type_t.NULL, "null") or_return
		}
		curr_token = token_list.peek(tokens, 0) or_return
		curr_syntax.left = syntax.create() or_return
		curr_syntax.left.token = token.create(nil, types.token_type_t.TERMINATOR, ";") or_return
		program.add(args, declaration) or_return
		if curr_token.type != types.token_type_t.COMMA {
			break
		}
	}
	curr_token = token_list.peek(tokens, 0) or_return
	if curr_token.type != types.token_type_t.RIGHT_PAREN {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	token_list.advance(tokens) or_return
	return args, types.exit_codes.OK
}

parse_function :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	declaration := syntax.create() or_return
	declaration.token = token_list.peek(tokens, 0) or_return
	token_list.advance(tokens) or_return
	curr_syntax := syntax.create() or_return
	declaration.right = curr_syntax
	curr_syntax.token = token_list.peek(tokens, 0) or_return
	if curr_syntax.token.type != types.token_type_t.IDENTIFIER {
		return nil, types.exit_codes.UNEXPECTED_SYNTAX
	}
	token_list.advance(tokens) or_return
	curr_syntax.args, _ = function_args(tokens, parent)
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token.type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens) or_return
	}
	curr_token = token_list.peek(tokens, 0) or_return
	if curr_token.type == types.token_type_t.LEFT_BRACE {
		curr_syntax.branch = branch(tokens, parent) or_return
		curr_syntax.branch.type = types.program_type_t.FUNCTION
	} else {
		prog := program.create(parent) or_return
		prog.type = types.program_type_t.FUNCTION
		curr_syntax.branch = prog
		prog_content := line(tokens, parent) or_return
		program.add(prog, prog_content) or_return
	}
	return declaration, types.exit_codes.OK
}

passed_function_args :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	declaration := syntax.create() or_return
	declaration.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	declaration.branch = program.create(nil) or_return
	for curr_token.type != .RIGHT_PAREN && curr_token.type != .END_OF_FILE {
		if curr_token.type == .COMMA {
			curr_token = token_list.advance(tokens) or_return
		}
		curr_syntax := expression(tokens) or_return
		program.add(declaration.branch, curr_syntax) or_return
		curr_token = token_list.peek(tokens, 0) or_return
		if curr_token.type == .RIGHT_PAREN {
			continue
		}
		curr_token = token_list.advance(tokens) or_return
	}
	if curr_token.type != .RIGHT_PAREN {
		return nil, .UNCLOSED_PARENTHESIS
	}
	token_list.advance(tokens) or_return
	return declaration, .OK
}
