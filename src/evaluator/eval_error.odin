package evaluator

import "../object"
import "../sys"
import "../types"
import "core:fmt"

eval_error :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	g_current_syntax = syntax
	val := eval_primary_expression(syntax.value, stck, program) or_return
	print_object_err(val)
	return
}

print_err :: proc(str: string) {
	str := translate_hex_colors(str)
	escaped := false
	for r in str {
		if escaped {
			switch r {
			case 'n':
				fmt.eprint("\n")
			case 't':
				fmt.eprint("\t")
			case:
				fmt.eprintf("\\%c", r)
			}
			escaped = false
		} else if r == '\\' {
			escaped = true
		} else {
			fmt.eprintf("%c", r)
		}
	}
	if escaped {
		fmt.eprint("\\")
	}
}

print_object_err :: proc(obj: ^types.object_t) -> (code: types.exit_codes) {
	switch obj.type {
	case .STRING:
		print_err(obj.data.(string))
	case .INT:
		num, err := object.int_to_number(int(obj.data.(int)))
		if !sys.is_error(err) do print_err(num)
	case .JSON:
		text := object.to_json_string(obj) or_return
		pretty_print_json(text)
	case .FLOAT, .ARRAY, .VECTOR, .NULL, .BOOL, .FUNCTION, .FILE:
		break
	}
	return
}
