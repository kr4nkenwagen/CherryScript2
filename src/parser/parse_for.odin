package parser

import "../syntax"
import "../token_list"
import "../types"


parse_for :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	sntx: ^types.syntax_t,
	code: types.exit_codes,
) {
	curr_syntax := syntax.create() or_return
	curr_syntax.token = token_list.peek(tokens, 0) or_return
	curr_token := token_list.advance(tokens) or_return
	if curr_token.type == .LEFT_PAREN do curr_token = token_list.advance(tokens) or_return
	component_1 := line(tokens, parent) or_return
	curr_token = token_list.peek(tokens, 0) or_return
	if curr_token.type == .RIGHT_PAREN || curr_token.type == .LEFT_BRACE {
		parse_while_components(curr_syntax, component_1) or_return
	} else {
		component_2, component_3: ^types.syntax_t
		component_2 = line(tokens, parent) or_return
		component_3 = line(tokens, parent) or_return
		parse_for_components(curr_syntax, component_1, component_2, component_3)
		for curr_token.type != types.token_type_t.LEFT_BRACE {
			curr_token = token_list.advance(tokens) or_return
		}
	}
	if curr_token.type == .RIGHT_PAREN do curr_token = token_list.advance(tokens) or_return
	curr_syntax.branch = branch(tokens, parent) or_return
	curr_syntax.branch.type = .LOOP
	return curr_syntax, .OK
}

parse_while_components :: proc(
	parent: ^types.syntax_t,
	component: ^types.syntax_t,
) -> (
	code: types.exit_codes,
) {
	parent.value = component
	return .OK
}

parse_for_components :: proc(
	parent: ^types.syntax_t,
	component_1: ^types.syntax_t,
	component_2: ^types.syntax_t,
	component_3: ^types.syntax_t,
) -> (
	code: types.exit_codes,
) {
	parent.left = component_1
	parent.value = component_2
	parent.right = component_3
	return .OK
}
