package parser

import "../syntax"
import "../sys"
import "../token_list"
import "../types"

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
	curr_tok, tok_err := token_list.peek(tokens, 0)
	if sys.is_error(tok_err) {
		return nil, tok_err
	}
	for curr_tok.type != types.token_type_t.LEFT_BRACE {
		_, adv_err = token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		curr_tok, tok_err = token_list.peek(tokens, 0)
		if sys.is_error(tok_err) {
			return nil, tok_err
		}
	}
	curr_syntax.branch, curr_syntax_err = branch(tokens, parent)
	if sys.is_error(curr_syntax_err) {
		return nil, curr_syntax_err
	}
	curr_syntax.branch.type = types.program_type_t.LOOP
	return curr_syntax, types.exit_codes.OK
}
