package sys

import "../token_list"
import "../types"
import "core:fmt"

is_error :: proc(exit_code: types.exit_codes) -> bool {
	return exit_code != types.exit_codes.OK
}

print_error :: proc(error_code: types.exit_codes, tokens: ^types.token_list_t) {
	curr_token, _ := token_list.peek(tokens, 0)
	fmt.printf(
		"%s [%i:%i]: (%s)%s \n",
		error_code,
		curr_token.line,
		curr_token.column,
		curr_token.type,
		curr_token.literal,
	)
}
