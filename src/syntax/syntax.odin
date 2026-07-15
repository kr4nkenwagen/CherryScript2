package syntax

import "../types"

create :: proc() -> (^types.syntax_t, bool) {
	syntax := new(types.syntax_t)
	if syntax == nil {
		return nil, true
	}
	return syntax, false
}
