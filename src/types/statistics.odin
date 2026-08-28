package types

import "core:time"

statistics_t :: struct {
	current_syntax:      ^syntax_t,
	start_time:          ^time.Tick,
	force_print_newline: bool,
}
