package evaluator

import "../types"
import "core:fmt"

eval_clear :: proc() -> types.exit_codes {
	// \x1b[2J clears the screen, \x1b[H resets cursor position to top-left
	fmt.print("\x1b[2J\x1b[H")
	return .OK
}
