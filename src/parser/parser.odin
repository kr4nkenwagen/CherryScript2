package parser

import "../program"
import "../sys"
import "../token_list"
import "../types"

branch :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.program_t,
	types.exit_codes,
) {
	if tokens == nil || parent == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	if curr_token.type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens)
	}
	if curr_token.type != types.token_type_t.LEFT_BRACE {
		return nil, types.exit_codes.BRACKET_NOT_OPENED
	}
	_, adv_err := token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	prog, err := program.create(parent)
	if sys.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err = token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token.type != types.token_type_t.RIGHT_BRACE {
		if curr_token.type == types.token_type_t.END_OF_FILE {
			return nil, types.exit_codes.UNEXPECTED_EOF
		}
		synt: ^types.syntax_t
		prev_synt: ^types.syntax_t
		for curr_token.type != types.token_type_t.TERMINATOR &&
		    curr_token.type != types.token_type_t.RIGHT_BRACE {
			if synt == nil {
				synt_err: types.exit_codes
				synt, synt_err = statement(tokens, prog)
				if sys.is_error(synt_err) {
					return nil, synt_err
				}
				prev_synt = synt
				continue
			}
			synt, err = statement(tokens, prog)
			if sys.is_error(err) {
				continue
			}
			synt.left = prev_synt
			prev_synt = synt
		}
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		prog_err := program.add(prog, synt)
		if sys.is_error(prog_err) {
			return nil, prog_err
		}
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	_, adv_err = token_list.advance(tokens)
	if sys.is_error(adv_err) {
		return nil, adv_err
	}
	return prog, types.exit_codes.OK
}

line :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.syntax_t,
	types.exit_codes,
) {
	curr_syntax: ^types.syntax_t
	prev_syntax: ^types.syntax_t
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token.type != types.token_type_t.TERMINATOR &&
	    curr_token.type != types.token_type_t.RIGHT_PAREN {
		if curr_syntax == nil {
			curr_syntax_err: types.exit_codes
			curr_syntax, curr_syntax_err = statement(tokens, parent)
			if sys.is_error(curr_syntax_err) {
				return nil, curr_syntax_err
			}
			prev_syntax = curr_syntax
			continue
		}
		curr_syntax_err: types.exit_codes
		curr_syntax, curr_syntax_err = statement(tokens, parent)
		if sys.is_error(curr_syntax_err) {
			return nil, curr_syntax_err
		}
		if curr_syntax == nil {
			continue
		}
		curr_syntax.left = prev_syntax
		prev_syntax = curr_syntax
	}
	for curr_token.type == types.token_type_t.TERMINATOR {
		_, adv_err := token_list.advance(tokens)
		if sys.is_error(adv_err) {
			return nil, adv_err
		}
		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return curr_syntax, types.exit_codes.OK
}

run :: proc(
	tokens: ^types.token_list_t,
	parent: ^types.program_t,
) -> (
	^types.program_t,
	types.exit_codes,
) {
	if tokens == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	prog, err := program.create(parent)
	if sys.is_error(err) {
		return nil, err
	}
	curr_token, curr_token_err := token_list.peek(tokens, 0)
	if sys.is_error(curr_token_err) {
		return nil, curr_token_err
	}
	for curr_token != nil && curr_token.type != types.token_type_t.END_OF_FILE {
		for curr_token != nil &&
		    curr_token.type != types.token_type_t.TERMINATOR &&
		    curr_token.type != types.token_type_t.RIGHT_BRACE &&
		    curr_token.type != types.token_type_t.LEFT_BRACE {

			synt, synt_err := statement(tokens, parent)
			if sys.is_error(synt_err) {
				return nil, synt_err
			}

			if synt != nil {
				prog_err := program.add(prog, synt)
				if sys.is_error(prog_err) {
					return nil, prog_err
				}
			}

			curr_token, curr_token_err = token_list.peek(tokens, 0)
			if sys.is_error(curr_token_err) {
				return nil, curr_token_err
			}
		}

		if curr_token != nil &&
		   (curr_token.type == .TERMINATOR ||
				   curr_token.type == .RIGHT_BRACE ||
				   curr_token.type == .LEFT_BRACE) {
			_, adv_err := token_list.advance(tokens)
			if adv_err == types.exit_codes.RAN_OUT_OF_TOKENS {
				break
			}
			if sys.is_error(adv_err) {
				return nil, adv_err
			}
		}

		curr_token, curr_token_err = token_list.peek(tokens, 0)
		if sys.is_error(curr_token_err) {
			return nil, curr_token_err
		}
	}
	return prog, types.exit_codes.OK
}
