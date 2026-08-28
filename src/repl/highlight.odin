package repl

import "../sys"
import "core:strings"

paint_line :: proc(ed: ^Editor) -> string {
	b := strings.builder_make(context.temp_allocator)
	strings.write_string(&b, sys.CLR_CYAN)
	strings.write_string(&b, "> ")
	strings.write_string(&b, sys.CLR_RESET)
	strings.write_string(&b, sys.paint_code(string(ed.line[:]), context.temp_allocator))
	return strings.to_string(b)
}