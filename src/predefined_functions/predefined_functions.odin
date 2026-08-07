package predefined_functions

import "../debug"
import "../object"
import "../sys"
import "../types"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "core:sys/posix"

translate_hex_colors :: proc(input: string, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)
	i := 0
	for i < len(input) {
		if i + 3 <= len(input) && input[i:i + 3] == "[#]" {
			strings.write_string(&b, "\x1b[0m")
			i += 3
			continue
		}
		if i + 9 <= len(input) && input[i:i + 2] == "[#" && input[i + 8] == ']' {
			hex_str := input[i + 2:i + 8]
			r, ok1 := strconv.parse_int(hex_str[0:2], 16)
			g, ok2 := strconv.parse_int(hex_str[2:4], 16)
			b_val, ok3 := strconv.parse_int(hex_str[4:6], 16)
			if ok1 && ok2 && ok3 {
				fmt.sbprintf(&b, "\x1b[38;2;%d;%d;%dm", r, g, b_val)
				i += 9
				continue
			}
		}
		strings.write_byte(&b, input[i])
		i += 1
	}
	return strings.to_string(b)
}


print_out :: proc(str: string, debug_mode: bool) {
	str := translate_hex_colors(str)
	if debug_mode {
		append(&debug.g_output_log, str)
		return
	}
	for i := 0; i < len(str); i += 1 {
		if str[i] == '\\' && i + 1 < len(str) {
			i += 1
			switch str[i] {
			case 'n':
				fmt.printf("%c", 10)
				continue
			case 't':
				fmt.printf("%c", 9)
				continue
			case:
				i -= 1
			}
		}
		fmt.printf("%c", str[i])
	}
}

print :: proc(obj: ^types.object_t, debug_mode: bool) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	switch obj.type {
	case .STRING:
		print_out(obj.data.(string), debug_mode)
	case .INT:
		num, err := object.int_to_number(int(obj.data.(int)))
		if !sys.is_error(err) {
			print_out(num, debug_mode)
		}
	case .FLOAT, .ARRAY, .VECTOR, .NULL, .BOOL, .FUNCTION, .FILE:
		break
	}
	return .OK
}

println :: proc(obj: ^types.object_t, debug_mode: bool) -> types.exit_codes {
	if obj == nil {
		return .OBJECT_IS_NIL
	}
	newline, newline_err := object.create_string("\n")
	if sys.is_error(newline_err) {
		return newline_err
	}
	formated_obj, formated_obj_err := object.add(obj, newline)
	if sys.is_error(formated_obj_err) {
		return formated_obj_err
	}
	return print(formated_obj, debug_mode)
}

len_func :: proc(obj: ^types.object_t) -> (^types.object_t, types.exit_codes) {
	length, length_err := object.length(obj)
	if sys.is_error(length_err) {
		return nil, length_err
	}
	return object.create_int(length)
}

in_func :: proc() -> (^types.object_t, types.exit_codes) {
	buf: [256]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil {
		return nil, .INTERPRETER_ERROR
	}
	raw_input := string(buf[:n])
	input := strings.trim_space(raw_input)
	heap_input := strings.clone(input)
	return object.create_string(heap_input)
}

key_func :: proc() -> (^types.object_t, types.exit_codes) {
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
	return object.create_string(heap_input)}
