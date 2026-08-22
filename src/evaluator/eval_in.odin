package evaluator

import "../object"
import "../types"
import "core:os"
import "core:strings"

eval_in :: proc() -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil do return nil, .FAILED_TO_READ_BUFFER_IN_EVAL_IN
	raw_input := string(buf[:n])
	input := strings.trim_space(raw_input)
	heap_input := strings.clone(input)
	ret_obj = object.create_string(heap_input) or_return
	return
}
