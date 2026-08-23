package sys

import "../types"
import "core:strings"

error_messages := #partial [types.exit_codes]string {
	.OK                                 = "All good hombre!",
	.UNEXPECTED_MEMBER_IN_EVAL_TERMINAL = "'%1' does not exist in terminal.",
}

parse_error :: proc(code: types.exit_codes, token: ^types.token_t) -> (result: string) {
	result, _ = strings.replace_all(error_messages[code], "%1", token.literal)
	return
}
