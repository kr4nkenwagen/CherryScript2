package evaluator

import "../object"
import "../types"
import "core:os"
import "core:strings"
import "core:sys/posix"

eval_key :: proc() -> (ret_obj: ^types.object_t, code: types.exit_codes) {
	fd: posix.FD = posix.STDIN_FILENO
	old_termios: posix.termios
	if posix.tcgetattr(fd, &old_termios) != .OK do return nil, .FAILED_TO_GET_POSICS_EVIRONMENT_IN_EVAL_KEY
	new_termios := old_termios
	new_termios.c_lflag -= {.ICANON, .ECHO}
	if posix.tcsetattr(fd, .TCSANOW, &new_termios) != .OK do return nil, .FAILED_TO_SET_TCSANOW_IN_EVAL_KEY
	defer posix.tcsetattr(fd, .TCSANOW, &old_termios)
	buf: [1]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil do return nil, .FAILED_TO_READ_INPUT_BUFFER_IN_EVAL_KEY
	raw_input := string(buf[:n])
	input := strings.trim_space(raw_input)
	heap_input := strings.clone(input)
	ret_obj = object.create_string(heap_input) or_return
	return
}
