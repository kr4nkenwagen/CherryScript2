package parser

import "../program"
import "../syntax"
import "../token"
import "../token_list"
import "../types"

branch :: proc(tokens: ^types.token_list_t, parent: ^types.program_t) -> (^types.program_t, bool) {
	if tokens == nil || parent == nil {
		return nil, true
	}
	if token_list.peek(tokens, 0).type == types.token_type_t.TERMINATOR {
		token_list.advance(tokens)
	}
	if token_list.peek(tokens, 0).type != types.token_type_t.LEFT_BRACE {
		//ERROR bracket not opened
		return nil, true
	}
	token_list.advance(tokens)
	prog, err := program.create(parent)
	if err {
		return nil, true
	}
	for token_list.peek(tokens, 0).type != types.token_type_t.RIGHT_BRACE {
		if token_list.peek(tokens, 0).type == types.token_type_t.END_OF_FILE {
			// ERROR unexpected end of file
			return nil, true
		}
		synt: ^types.syntax_t
		prev_synt: ^types.syntax_t
		for token_list.peek(tokens, 0).type != types.token_type_t.TERMINATOR &&
		    token_list.peek(tokens, 0).type != types.token_type_t.RIGHT_BRACE {
			if synt == nil {
				synt, err = statement(tokens, prog)
				if err {
					return nil, true
				}
				prev_synt = synt
				continue
			}
			synt, err = statement(tokens, prog)
			if err {
				continue
			}
			synt.left = prev_synt
			prev_synt = synt
		}
		token_list.advance(tokens)
		program.add(prog, synt)
	}
	token_list.advance(tokens)
	return prog, false
}

line :: proc(tokens: ^types.token_list_t, parent: ^types.program_t) -> (^types.syntax_t, bool) {

}


run :: proc(tokens: ^types.token_list_t, parent: ^types.program_t) -> (^types.program_t, bool) {
	if tokens == nil {
		return nil, true
	}
	prog, err := program.create(parent)
	if err {
		return nil, true
	}
	for token_list.peek(tokens, 0).type != types.token_type_t.END_OF_FILE {
		synt: ^syntax.syntax_t
		prev_synt: ^syntax.syntax_t
		for token_list.peek(tokens, 0).type != token.type_t.TERMINATOR &&
		    token_list.peek(tokens, 0).type != token.type_t.RIGHT_BRACE &&
		    token_list.peek(tokens, 0).type != token.type_t.LEFT_BRACE {
			if synt == nil {
				synt, err = statement(tokens, prog)
			}
		}
	}

}
