package evaluator

import "../object"
import "../types"
import "core:os"
import "core:strings"
import "core:sys/posix"

eval_key :: proc() -> (^types.object_t, types.exit_codes) {
	fd: posix.FD = posix.STDIN_FILENO
	old_termios: posix.termios
	if posix.tcgetattr(fd, &old_termios) != .OK {
		return nil, .INTERPRETER_ERROR
	}
	new_termios := old_termios
	new_termios.c_lflag -= {.ICANON, .ECHO}
	if posix.tcsetattr(fd, .TCSANOW, &new_termios) != .OK {
		return nil, .INTERPRETER_ERROR
	}
	defer posix.tcsetattr(fd, .TCSANOW, &old_termios)
	buf: [1]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil {
		return nil, .INTERPRETER_ERROR
	}
	raw_input := string(buf[:n])
	input := strings.trim_space(raw_input)
	heap_input := strings.clone(input)
	return object.create_string(heap_input)
}
