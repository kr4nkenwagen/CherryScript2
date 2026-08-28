package evaluator

import "../object"
import "../types"
import "core:sys/linux"

eval_terminal :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	type := syntax.value.token.literal
	program.stats.current_syntax = syntax.value
	switch type {
	case "width":
		ws := get_terminal_size()
		return object.create_int(int(ws.ws_col))

	case "height":
		ws := get_terminal_size()
		return object.create_int(int(ws.ws_row))

	case "pixel_width":
		ws := get_terminal_size()
		return object.create_int(int(ws.ws_xpixel))

	case "pixel_height":
		ws := get_terminal_size()
		return object.create_int(int(ws.ws_ypixel))

	case:
		code = .UNEXPECTED_MEMBER_IN_EVAL_TERMINAL
	}
	return
}

winsize :: struct {
	ws_row:    u16,
	ws_col:    u16,
	ws_xpixel: u16,
	ws_ypixel: u16,
}

get_terminal_size :: proc() -> (ws: winsize) {
	linux.ioctl(linux.Fd(1), linux.TIOCGWINSZ, uintptr(&ws))
	return
}
