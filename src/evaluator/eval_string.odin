package evaluator

import "../object"
import "../types"
import "core:strings"

eval_string :: proc(
	syntax: ^types.syntax_t,
	stck: ^types.vm_t,
	program: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	program.stats.current_syntax = syntax
	type := syntax.value.token.literal
	args := eval_builtin_function_args(syntax.value, stck, program) or_return
	defer delete(args)
	switch type {
	case "contains":
		return str_contains(args)
	case "first_index_of":
		return str_first_index_of(args)
	case "last_index_of":
		return str_last_index_of(args)
	case "first_index_of_from":
		return str_first_index_of_from(args)
	case "trim_start":
		return str_trim_start(args)
	case "trim_end":
		return str_trim_end(args)
	case "trim":
		return str_trim(args)
	case "to_upper":
		return str_to_upper(args)
	case "to_lower":
		return str_to_lower(args)
	case "pad_start":
		return str_pad_start(args)
	case "pad_end":
		return str_pad_end(args)
	case "replace_all":
		return str_replace_all(args)
	case:
		code = .UNEXPECTED_MEMBER_IN_EVAL_STRING
	}
	return
}

str_contains :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_CONTAINS
	str := args[0]
	sep := args[1]
	if str.type != .STRING || sep.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_CONTAINS
	obj = object.create_bool(strings.contains(str.data.(string), sep.data.(string))) or_return
	return
}

str_first_index_of :: proc(
	args: []^types.object_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_FIRST_INDEX_OF
	str := args[0]
	search := args[1]
	if str.type != .STRING || search.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_FIRST_INDEX_OF
	obj = object.create_int(strings.index(str.data.(string), search.data.(string))) or_return
	return
}

str_last_index_of :: proc(
	args: []^types.object_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_LAST_INDEX_OF
	str := args[0]
	search := args[1]
	if str.type != .STRING || search.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_LAST_INDEX_OF
	obj = object.create_int(strings.last_index(str.data.(string), search.data.(string))) or_return
	return
}

str_first_index_of_from :: proc(
	args: []^types.object_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if len(args) != 3 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_INDEX_OF_FROM
	str := args[0]
	search := args[1]
	start := args[2]
	if str.type != .STRING || search.type != .STRING || start.type != .INT do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_INDEX_OF_FROM
	sub, _ := strings.substring_from(str.data.(string), start.data.(int))
	obj = object.create_int(strings.index(sub, search.data.(string))) or_return
	return
}

str_trim_start :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_TRIM_START
	str := args[0]
	if str.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_TRIM_START
	obj = object.create_string(strings.trim_left_space(str.data.(string))) or_return
	return
}

str_trim_end :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_TRIM_END
	str := args[0]
	if str.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_TRIM_END
	obj = object.create_string(strings.trim_right_space(str.data.(string))) or_return
	return
}

str_trim :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_TRIM
	str := args[0]
	if str.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_TRIM
	obj = object.create_string(strings.trim_space(str.data.(string))) or_return
	return
}

str_to_upper :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_TO_UPPER
	str := args[0]
	if str.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_TO_UPPER
	obj = object.create_string(strings.to_upper(str.data.(string))) or_return
	return
}

str_to_lower :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 1 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_TO_LOWER
	str := args[0]
	if str.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_TO_LOWER
	obj = object.create_string(strings.to_lower(str.data.(string))) or_return
	return
}

str_pad_start :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_PAD_START
	str := args[0]
	count := args[1]
	if str.type != .STRING || count.type != .INT do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_PAD_START
	total_count := len(str.data.(string)) + count.data.(int)
	obj = object.create_string(
		strings.right_justify(str.data.(string), total_count, " "),
	) or_return
	return
}

str_pad_end :: proc(args: []^types.object_t) -> (obj: ^types.object_t, code: types.exit_codes) {
	if len(args) != 2 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_PAD_END
	str := args[0]
	count := args[1]
	if str.type != .STRING || count.type != .INT do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_PAD_END
	total_count := len(str.data.(string)) + count.data.(int)
	obj = object.create_string(strings.left_justify(str.data.(string), total_count, " ")) or_return
	return
}

str_replace_all :: proc(
	args: []^types.object_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if len(args) != 3 do return nil, .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_REPLACE_ALL
	str := args[0]
	old := args[1]
	new := args[2]
	if str.type != .STRING || old.type != .STRING || new.type != .STRING do return nil, .INCORRECT_PARAMETER_TYPE_IN_STRING_REPLACE_ALL
	replaced, _ := strings.replace_all(str.data.(string), old.data.(string), new.data.(string))
	obj = object.create_string(replaced) or_return
	return
}
