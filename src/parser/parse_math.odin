package parser

import "../syntax"
import "../token_list"
import "../types"

parse_math :: proc(
	tokens: ^types.token_list_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	sntx = syntax.create() or_return
	sntx.token = token_list.peek(tokens, 0) or_return
	dot := token_list.advance(tokens) or_return
	if dot.type != .DOT do return nil, .EXPECTED_DOT_IN_PARSE_MATH
	ident := token_list.advance(tokens) or_return
	if ident.type != .IDENTIFIER do return nil, .EXPECTED_IDENTIFIER_IN_PARSE_MATH
	val := syntax.create() or_return
	val.token = ident
	sntx.value = val
	next := token_list.peek(tokens, 1) or_return
	if next.type == .LEFT_PAREN {
		token_list.advance(tokens) or_return
		sntx.value.value = passed_function_args(tokens) or_return
	} else {
		token_list.advance(tokens) or_return
	}
	return
}
