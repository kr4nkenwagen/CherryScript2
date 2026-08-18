package evaluator

import "../object"
import "../types"
import "core:os"
import "core:strings"

eval_in :: proc() -> (^types.object_t, types.exit_codes) {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil do return nil, .INTERPRETER_ERROR
	raw_input := string(buf[:n])
	input := strings.trim_space(raw_input)
	heap_input := strings.clone(input)
	return object.create_string(heap_input)
}
