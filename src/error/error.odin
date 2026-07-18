package error

import "../types"

is_error :: proc(exit_code: types.exit_codes) -> bool {
	return exit_code != types.exit_codes.OK
}
