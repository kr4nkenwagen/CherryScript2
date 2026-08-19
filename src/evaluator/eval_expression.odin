package evaluator

import "../debug"
import "../object"
import "../sys"
import "../types"
import "core:strconv"
import "core:strings"

eval_primary_expression :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil do return nil, .OBJECT_IS_NIL
	if g_debug {
		debug.prompt_user(syntax.token, stck)
	}
	#partial switch syntax.token.type {
	case .REMOVE:
		return nil, eval_variable_remove(syntax, stck, program)
	case .RM:
		return nil, eval_file_remove(syntax, stck, program)
	case .ERROR:
		return nil, eval_error(syntax, stck, program)
	case .OUT:
		return nil, eval_out(syntax, stck, program)
	case .SLEEP:
		return nil, eval_sleep(syntax, stck, program)
	case .CLEAR:
		return nil, eval_clear()
	case .CONTINUE:
		return nil, eval_continue(syntax, stck, program)
	case .BREAK:
		return nil, eval_break(syntax, stck, program)
	case .RETURN:
		return nil, eval_return(syntax, stck, program)
	case .PRINT_LINE:
		val, err := eval_primary_expression(syntax.value, stck, program)
		eval_println(val, g_debug)
		return nil, .OK
	case .FOR:
		return nil, eval_for(syntax, stck, program)
	case .PRINT:
		val := eval_primary_expression(syntax.value, stck, program) or_return
		eval_print(val, g_debug)
		return nil, .OK
	case .FUNCTION:
		return nil, function_declaration(syntax, stck)
	case .IF:
		return nil, eval_if(syntax, stck, program)
	case .LEFT_BRACKET:
		return eval_array_declaration(syntax, stck, program)
	case .COLON, .COLON_HAT, .DOT_DOT:
		return eval_string_operation_expression(syntax, stck, program)
	case .BANG:
		return eval_unary_expression(syntax, stck, program)
	case .EQUAL_EQUAL, .BANG_EQUAL, .GREATER_EQUAL, .LESS_EQUAL, .LESS, .GREATER:
		return eval_comparison_expression(syntax, stck, program)
	case .EQUAL, .PLUS_EQUAL, .MINUS_EQUAL, .STAR_EQUAL, .SLASH_EQUAL:
		err := eval_assignment_expression(syntax, stck, program)
		return nil, err
	case .CONST, .VAR:
		return nil, variable_declarations(syntax, stck, program)
	case .GLOBAL:
		return nil, eval_global(syntax, stck, program)
	case .AND, .OR:
		return eval_and_or(syntax, stck, program)
	case .IDENTIFIER:
		return eval_identifier(syntax, stck, program)
	case .STRING_WRAPPER:
		return object.create_string(syntax.token.literal)
	case .TIME:
		return eval_time(syntax, stck, program)
	case .AT:
		return object.create_file(syntax.token.literal)
	case .IN:
		return eval_in()
	case .KEY:
		return eval_key()
	case .JSON:
		return eval_json(syntax, stck, program)
	case .GET:
		return eval_get(syntax, stck, program)
	case .NUMBER:
		return eval_number(syntax)
	case .NULL:
		return object.create_null()
	case .TRUE:
		return object.create_bool(true)
	case .FALSE:
		return object.create_bool(false)
	case .LENGTH:
		val := eval_primary_expression(syntax.value.branch.statements[0], stck, program) or_return
		return eval_length(val)
	case .EXISTS:
		val := eval_primary_expression(syntax.value.branch.statements[0], stck, program) or_return
		return eval_exists(val)

	case .RIGHT_ARROW:
		return eval_file_extraction(syntax, stck, program)
	case .PLUS, .MINUS, .STAR, .SLASH, .MODULUS:
		return eval_binary_expression(syntax, stck, program)
	case:
		return nil, .INTERPRETER_ERROR
	}
}

eval_file_extraction :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	file := eval_primary_expression(syntax.left, stck, program) or_return
	index := eval_primary_expression(syntax.right, stck, program) or_return
	if syntax.right.token.type == .LENGTH {
		if syntax.left.token.literal == syntax.right.value.branch.statements[0].token.literal {
			index.data = index.data.(int) - 1
		}
	}
	content := object.file_get(file.data.(types.object_file_t).name, index.data.(int)) or_return
	return object.create_string(content)
}

eval_number :: proc(syntax: ^types.syntax_t) -> (^types.object_t, types.exit_codes) {
	if syntax == nil do return nil, .OBJECT_IS_NIL
	if strings.contains(syntax.token.literal, ".") {
		val := strconv.parse_f64(syntax.token.literal) or_else 0.0
		return object.create_float(f32(val))
	} else {
		val := strconv.parse_int(syntax.token.literal) or_else 0
		return object.create_int(int(val))
	}
}

eval_string_operation_expression :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	left_hand_side := eval_primary_expression(syntax.left, stck, program) or_return
	right_hand_side := eval_primary_expression(syntax.right, stck, program) or_return
	#partial switch syntax.token.type {
	case .COLON:
		if right_hand_side.type == .INT {
			return object.substring(left_hand_side, 0, int(right_hand_side.data.(int)))
		}
		if right_hand_side.type == .STRING {
			position, err := object.position_of_first_instance(
				left_hand_side,
				right_hand_side.data.(string),
			)
			if sys.is_error(err) do return nil, err
			if position == -1 do return nil, .OK
			return object.substring(left_hand_side, 0, position)
		}
	case .COLON_HAT:
		if right_hand_side.type == .INT {
			size := object.length(left_hand_side) or_return
			len_val := int(right_hand_side.data.(int))
			return object.substring(left_hand_side, size - len_val, len_val)
		}
		if right_hand_side.type == .STRING {
			position := object.position_of_last_instance(
				left_hand_side,
				right_hand_side.data.(string),
			) or_return
			if position == -1 do return nil, .OK
			return object.substring(left_hand_side, position + 1, -1)
		}
	case .DOT_DOT:
		if left_hand_side.type == .STRING || right_hand_side.type == .STRING {
			return object.join_string(left_hand_side, right_hand_side)
		}
		if left_hand_side.type == .FLOAT || right_hand_side.type == .FLOAT {

			return object.join_string(left_hand_side, right_hand_side)
		}
		return nil, .ILLEGAL_OPERATION
	}
	return nil, .OK
}

eval_and_or :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil do return nil, .OBJECT_IS_NIL
	left_hand_side := eval_primary_expression(syntax.left, stck, program) or_return
	right_hand_side := eval_primary_expression(syntax.right, stck, program) or_return
	if left_hand_side.type != .BOOL || right_hand_side.type != .BOOL {
		return nil, .TYPE_MISMATCH
	}

	#partial switch syntax.token.type {
	case .AND:
		return object.create_bool(left_hand_side.data.(bool) && right_hand_side.data.(bool))
	case .OR:
		return object.create_bool(left_hand_side.data.(bool) || right_hand_side.data.(bool))
	}
	return nil, .OK
}

eval_unary_expression :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil do return nil, .OBJECT_IS_NIL
	left_hand_side := eval_primary_expression(syntax.left, stck, program) or_return
	if left_hand_side != nil && left_hand_side.type == .BOOL {
		return object.create_bool(!left_hand_side.data.(bool))
	}
	return nil, .ILLEGAL_OPERATION
}

eval_comparison_expression :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil do return nil, .OBJECT_IS_NIL
	left_hand_side := eval_primary_expression(syntax.left, stck, program) or_return
	right_hand_side := eval_primary_expression(syntax.right, stck, program) or_return
	#partial switch syntax.token.type {
	case .EQUAL_EQUAL:
		return object.equals(left_hand_side, right_hand_side)
	case .BANG_EQUAL:
		return object.not_equals(left_hand_side, right_hand_side)
	case .GREATER_EQUAL:
		return object.greater_equals(left_hand_side, right_hand_side)
	case .LESS_EQUAL:
		return object.less_equals(left_hand_side, right_hand_side)
	case .LESS:
		return object.less(left_hand_side, right_hand_side)
	case .GREATER:
		return object.greater(left_hand_side, right_hand_side)
	}
	return nil, .OK
}

divide_by_zero :: proc(a, b: ^types.object_t) -> bool {
	if (a.type == .INT && a.data.(int) == 0) ||
	   (a.type == .FLOAT && a.data.(f32) == 0) ||
	   (b.type == .INT && b.data.(int) == 0) ||
	   (b.type == .FLOAT && b.data.(f32) == 0) {
		return true
	}
	return false
}

eval_binary_expression :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if syntax == nil do return nil, .OBJECT_IS_NIL

	left_hand_side := eval_primary_expression(syntax.left, stck, program) or_return
	right_hand_side := eval_primary_expression(syntax.right, stck, program) or_return
	#partial switch syntax.token.type {
	case .PLUS:
		return object.add(left_hand_side, right_hand_side)
	case .MINUS:
		return object.subtract(left_hand_side, right_hand_side)
	case .STAR:
		return object.multiply(left_hand_side, right_hand_side)
	}

	if divide_by_zero(left_hand_side, right_hand_side) do return nil, .DIVISION_BY_ZERO

	#partial switch syntax.token.type {
	case .SLASH:
		return object.divide(left_hand_side, right_hand_side)
	case .MODULUS:
		return object.modulus(left_hand_side, right_hand_side)
	}
	return nil, .OK
}

eval_assignment_expression :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if syntax == nil {
		return .OBJECT_IS_NIL
	}
	if syntax.left.token.type == .LEFT_ARROW {
		right_hand_side := eval_primary_expression(syntax.right, stck, program) or_return
		file := eval_primary_expression(syntax.left.left, stck, program) or_return
		index := eval_primary_expression(syntax.left.right, stck, program) or_return
		object.file_set(
			file.data.(types.object_file_t).name,
			right_hand_side.data.(string),
			index.data.(int),
		)
		return .OK
	}
	left_hand_side := eval_primary_expression(syntax.left, stck, program) or_return
	right_hand_side := eval_primary_expression(syntax.right, stck, program) or_return
	if left_hand_side.is_const {
		return .CANNOT_ASSIGN_TO_CONSTANT
	}

	#partial switch syntax.token.type {
	case .EQUAL:
		return object.assign(left_hand_side, right_hand_side)
	case .PLUS_EQUAL:
		res := object.add(left_hand_side, right_hand_side) or_return
		return object.assign(left_hand_side, res)
	case .MINUS_EQUAL:
		res := object.subtract(left_hand_side, right_hand_side) or_return
		return object.assign(left_hand_side, res)
	case .STAR_EQUAL:
		res := object.multiply(left_hand_side, right_hand_side) or_return
		return object.assign(left_hand_side, res)
	case .SLASH_EQUAL:
		if divide_by_zero(left_hand_side, right_hand_side) {
			return .DIVISION_BY_ZERO
		}
		res := object.divide(left_hand_side, right_hand_side) or_return
		return object.assign(left_hand_side, res)
	}
	return .OK
}
