package syntax

import "../types"

create :: proc() -> (^types.syntax_t, types.exit_codes) {
	syntax := new(types.syntax_t)
	if syntax == nil {
		return nil, types.exit_codes.MEMORY_ALLOCATION_FAILED
	}
	return syntax, types.exit_codes.OK
}
