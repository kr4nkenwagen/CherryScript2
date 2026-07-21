package predefined_functions

import "../debug"
import "../object"
import "../sys"
import "../types"
import "core:fmt"

print_out :: proc(str: string, debug_mode: bool) {
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
	case .FLOAT, .ARRAY, .VECTOR, .NULL, .BOOL, .FUNCTION:
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
