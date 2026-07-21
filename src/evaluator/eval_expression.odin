package evaluator

import "../debug"
import "../object"
import "../predefined_functions"
import "../sys"
import "../types"
import "core:strconv"
import "core:strings"

eval_primary_expression :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	if g_debug {
		debug.prompt_user(syntax.token, vm)
	}
	#partial switch syntax.token.type {
	case .REMOVE:
		return nil, eval_variable_remove(syntax, vm, program)
	case .ERROR:
		return nil, eval_error(syntax, vm, program)
	case .OUT:
		return nil, eval_out(syntax, vm, program)
	case .CONTINUE:
		return nil, eval_continue(syntax, vm, program)
	case .BREAK:
		return nil, eval_break(syntax, vm, program)
	case .RETURN:
		return nil, eval_return(syntax, vm, program)
	case .PRINT_LINE:
		val, err := eval_primary_expression(syntax.value, vm, program)
		if sys.is_error(err) {
			return nil, err
		}
		predefined_functions.println(val, g_debug)
		return nil, .OK
	case .FOR:
		return nil, eval_for(syntax, vm, program)
	case .PRINT:
		val, err := eval_primary_expression(syntax.value, vm, program)
		if sys.is_error(err) {
			return nil, err
		}
		predefined_functions.print(val, g_debug)
		return nil, .OK
	case .FUNCTION:
		return nil, function_declaration(syntax, vm)
	case .IF:
		return nil, eval_if(syntax, vm, program)
	case .LEFT_BRACKET:
		return eval_array_declaration(syntax, vm, program)
	case .WHILE:
		return nil, eval_while(syntax, vm, program)
	case .COLON, .COLON_HAT, .DOT_DOT:
		return eval_string_operation_expression(syntax, vm, program)
	case .BANG:
		return eval_unary_expression(syntax, vm, program)
	case .EQUAL_EQUAL, .BANG_EQUAL, .GREATER_EQUAL, .LESS_EQUAL, .LESS, .GREATER:
		return eval_comparison_expression(syntax, vm, program)
	case .EQUAL, .PLUS_EQUAL, .MINUS_EQUAL, .STAR_EQUAL, .SLASH_EQUAL:
		err := eval_assignment_expression(syntax, vm, program)
		return nil, err
	case .CONST, .VAR:
		return nil, variable_declarations(syntax, vm, program)
	case .IDENTIFIER:
		return eval_identifier(syntax, vm, program)
	case .STRING_WRAPPER:
		return object.create_string(syntax.token.literal)
	case .NUMBER:
		return eval_number(syntax)
	case .NIL:
		return object.create_null()
	case .TRUE:
		return object.create_bool(true)
	case .FALSE:
		return object.create_bool(false)
	case .PLUS, .MINUS, .STAR, .SLASH, .MODULUS:
		return eval_binary_expression(syntax, vm, program)
	case:
		return nil, .INTERPRETER_ERROR
	}
}

eval_number :: proc(syntax: ^types.syntax_t) -> (^types.object_t, types.exit_codes) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
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
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	left_hand_side, left_err := eval_primary_expression(syntax.left, vm, program)
	if sys.is_error(left_err) do return nil, left_err
	right_hand_side, right_err := eval_primary_expression(syntax.right, vm, program)
	if sys.is_error(right_err) do return nil, right_err
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
			size, err := object.length(left_hand_side)
			if sys.is_error(err) do return nil, err
			len_val := int(right_hand_side.data.(int))
			return object.substring(left_hand_side, size - len_val, len_val)
		}
		if right_hand_side.type == .STRING {
			position, err := object.position_of_last_instance(
				left_hand_side,
				right_hand_side.data.(string),
			)
			if sys.is_error(err) do return nil, err
			if position == -1 do return nil, .OK
			return object.substring(left_hand_side, position + 1, -1)
		}
	case .DOT_DOT:
		if left_hand_side.type == .STRING || right_hand_side.type == .STRING {
			return object.add(left_hand_side, right_hand_side)
		}
		return nil, .ILLEGAL_OPERATION
	}
	return nil, .OK
}

eval_and_or :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	left_hand_side, left_err := eval_primary_expression(syntax.left, vm, program)
	if sys.is_error(left_err) {
		return nil, left_err
	}

	right_hand_side, right_err := eval_primary_expression(syntax.right, vm, program)
	if sys.is_error(right_err) {
		return nil, right_err
	}
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
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	right_hand_side, right_err := eval_primary_expression(syntax.right, vm, program)
	if sys.is_error(right_err) {
		return nil, right_err
	}
	if right_hand_side != nil && right_hand_side.type == .BOOL {
		return object.create_bool(!right_hand_side.data.(bool))
	}
	return nil, .ILLEGAL_OPERATION
}

eval_comparison_expression :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}
	left_hand_side, left_err := eval_primary_expression(syntax.left, vm, program)
	if sys.is_error(left_err) {
		return nil, left_err
	}
	right_hand_side, right_err := eval_primary_expression(syntax.right, vm, program)
	if sys.is_error(right_err) {
		return nil, right_err
	}
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
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if syntax == nil {
		return nil, .OBJECT_IS_NIL
	}

	left_hand_side, left_err := eval_primary_expression(syntax.left, vm, program)
	if sys.is_error(left_err) {
		return nil, left_err
	}
	right_hand_side, right_err := eval_primary_expression(syntax.right, vm, program)
	if sys.is_error(right_err) {
		return nil, right_err
	}
	#partial switch syntax.token.type {
	case .PLUS:
		return object.add(left_hand_side, right_hand_side)
	case .MINUS:
		return object.subtract(left_hand_side, right_hand_side)
	case .STAR:
		return object.multiply(left_hand_side, right_hand_side)
	}

	if divide_by_zero(left_hand_side, right_hand_side) {
		return nil, .DIVISION_BY_ZERO
	}

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
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if syntax == nil {
		return .OBJECT_IS_NIL
	}
	left_hand_side, left_err := eval_primary_expression(syntax.left, vm, program)
	if sys.is_error(left_err) {
		return left_err
	}
	right_hand_side, right_err := eval_primary_expression(syntax.right, vm, program)
	if sys.is_error(right_err) {
		return right_err
	}
	if left_hand_side.is_const {
		return .CANNOT_ASSIGN_TO_CONSTANT
	}

	#partial switch syntax.token.type {
	case .EQUAL:
		return object.assign(left_hand_side, right_hand_side)
	case .PLUS_EQUAL:
		res, err := object.add(left_hand_side, right_hand_side)
		if sys.is_error(err) do return err
		return object.assign(left_hand_side, res)
	case .MINUS_EQUAL:
		res, err := object.subtract(left_hand_side, right_hand_side)
		if sys.is_error(err) do return err
		return object.assign(left_hand_side, res)
	case .STAR_EQUAL:
		res, err := object.multiply(left_hand_side, right_hand_side)
		if sys.is_error(err) do return err
		return object.assign(left_hand_side, res)
	case .SLASH_EQUAL:
		if divide_by_zero(left_hand_side, right_hand_side) {
			return .DIVISION_BY_ZERO
		}
		res, err := object.divide(left_hand_side, right_hand_side)
		if sys.is_error(err) {
			return err
		}
		return object.assign(left_hand_side, res)
	}
	return .OK
}
