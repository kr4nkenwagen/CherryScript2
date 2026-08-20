package evaluator

import "../debug"
import "../object"
import "../sys"
import "../types"
import "core:fmt"
import "core:strconv"
import "core:strings"

translate_hex_colors :: proc(input: string, allocator := context.allocator) -> string {
	b := strings.builder_make(allocator)
	i := 0
	for i < len(input) {
		if i + 2 < len(input) && input[i:i + 2] == "[#" {
			if input[i + 2] == ']' {
				strings.write_string(&b, "\x1b[0m")
				i += 3
				continue
			}
			if i + 6 <= len(input) && input[i + 5] == ']' {
				hex_str := input[i + 2:i + 5]
				r_digit, ok1 := strconv.parse_int(hex_str[0:1], 16)
				g_digit, ok2 := strconv.parse_int(hex_str[1:2], 16)
				b_digit, ok3 := strconv.parse_int(hex_str[2:3], 16)
				if ok1 && ok2 && ok3 {
					fmt.sbprintf(
						&b,
						"\x1b[38;2;%d;%d;%dm",
						r_digit * 17,
						g_digit * 17,
						b_digit * 17,
					)
					i += 6
					continue
				}
			}
			if i + 9 <= len(input) && input[i + 8] == ']' {
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
	escaped := false
	for r in str {
		if escaped {
			switch r {
			case 'n':
				fmt.print("\n")
			case 't':
				fmt.print("\t")
			case:
				fmt.printf("\\%c", r)
			}
			escaped = false
		} else if r == '\\' {
			escaped = true
		} else {
			fmt.printf("%c", r)
		}
	}
	if escaped {
		fmt.print("\\")
	}
}

eval_print :: proc(obj: ^types.object_t, debug_mode: bool) -> types.exit_codes {
	if obj == nil do return .OBJECT_IS_NIL_IN_EVAL_PRINT
	switch obj.type {
	case .STRING:
		print_out(obj.data.(string), debug_mode)
	case .INT:
		num, err := object.int_to_number(int(obj.data.(int)))
		if !sys.is_error(err) do print_out(num, debug_mode)
	case .FLOAT, .ARRAY, .VECTOR, .NULL, .BOOL, .FUNCTION, .FILE, .JSON:
		break
	}
	return .OK
}
