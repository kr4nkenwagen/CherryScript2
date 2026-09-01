package parser

import "../program"
import "../syntax"
import "../token"
import "../token_list"
import "../types"
import "core:fmt"

function_args :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	args: ^types.program_t,
	code: types.exit_codes,
) {
	args = program.create(parent) or_return
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token.type != .LEFT_PAREN {
		return nil, .EXPECTED_LEFT_PAREN_IN_FUNCTION_ARGS
	}
	curr_token = token_list.advance(tokens) or_return
	for {
		if curr_token.type == .COMMA do curr_token = token_list.advance(tokens) or_return
		if curr_token.type != .VAR && curr_token.type != .CONST do break
		declaration := syntax.create() or_return
		declaration.token = curr_token
		curr_token = token_list.advance(tokens) or_return
		if curr_token.type != .IDENTIFIER do return nil, .EXPECTED_IDENTIFIER_IN_FUNCTION_ARGS
		curr_syntax := syntax.create() or_return
		curr_syntax.token = curr_token
		declaration.left = curr_syntax
		eq_token := token_list.advance(tokens) or_return

		if eq_token.type == .EQUAL {
			token_list.advance(tokens) or_return
			curr_syntax.value, _ = expression(tokens)
		} else {
			curr_syntax.value = syntax.create() or_return
			curr_syntax.value.token = token.create(nil, .NULL, "null") or_return
		}
		curr_token = token_list.peek(tokens, 0) or_return
		curr_syntax.left = syntax.create() or_return
		curr_syntax.left.token = token.create(nil, .TERMINATOR, ";") or_return
		program.add(args, declaration) or_return
		if curr_token.type != .COMMA do break
	}
	curr_token = token_list.peek(tokens, 0) or_return
	if curr_token.type != .RIGHT_PAREN do return nil, .EXPECTED_RIGHT_PAREN_IN_FUNCTION_ARGS
	token_list.advance(tokens) or_return
	return
}

parse_function :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = syntax.create() or_return
	sntx.token = token_list.peek(tokens, 0) or_return
	token_list.advance(tokens) or_return
	curr_syntax := syntax.create() or_return
	sntx.right = curr_syntax
	curr_syntax.token = token_list.peek(tokens, 0) or_return
	if curr_syntax.token.type != .IDENTIFIER do return nil, .EXPECTED_IDENTIFIER_IN_PARSE_FUNCTION
	token_list.advance(tokens) or_return
	curr_syntax.args, _ = function_args(tokens, parent)
	curr_token := token_list.peek(tokens, 0) or_return
	if curr_token.type == .TERMINATOR do token_list.advance(tokens) or_return
	curr_token = token_list.peek(tokens, 0) or_return
	if curr_token.type == .LEFT_BRACE {
		curr_syntax.branch = branch(tokens, parent) or_return
		curr_syntax.branch.type = .FUNCTION
	} else {
		prog := program.create(parent) or_return
		prog.type = .FUNCTION
		curr_syntax.branch = prog
		prog_content := line(tokens, parent) or_return
		program.add(prog, prog_content) or_return
	}
	return
}

passed_function_args :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = syntax.create() or_return
	sntx.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	sntx.branch = program.create(nil) or_return
	for curr_token.type != .RIGHT_PAREN && curr_token.type != .END_OF_FILE {
		if curr_token.type == .COMMA do curr_token = token_list.advance(tokens) or_return
		curr_syntax := expression(tokens) or_return
		nxt, _ := token_list.peek(tokens, 0)
		program.add(sntx.branch, curr_syntax) or_return
		curr_token = token_list.peek(tokens, 0) or_return
		if curr_token.type == .RIGHT_PAREN do continue
		curr_token = token_list.advance(tokens) or_return
	}
	if curr_token.type != .RIGHT_PAREN do return nil, .UNCLOSED_PARENTHESIS_IN_PASSED_FUNCTION_ARGS
	token_list.advance(tokens) or_return
	return
}
