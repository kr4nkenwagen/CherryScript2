package sys

import "../token_list"
import "../types"
import "core:fmt"

g_has_errored := false

is_error :: proc(exit_code: types.exit_codes, loc := #caller_location) -> (err: bool) {
	if exit_code == types.exit_codes.OK do return
	err = true
	if g_has_errored do return true
	g_has_errored = true
	fmt.printfln("ERROR! Called from %v (line %v)", loc.procedure, loc.line)
	fmt.printfln("File: %v:%v:%v", loc.file_path, loc.line, loc.column)
	return
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
