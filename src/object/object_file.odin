package object

import "../object"
import "../types"
import "core:os"
import "core:strings"

file_set :: proc(
	filepath: string,
	new_text: string,
	target_index: int,
) -> (
	code: types.exit_codes,
) {
	if target_index < 0 {
		return .INDEX_OUT_OF_BOUNDS_IN_FILE_SET
	}
	if !os.exists(filepath) {
		_, err := os.create(filepath)
		if err != os.General_Error.None {
			return .FAILED_TO_CREATE_FILE_IN_FILE_SET
		}
	}
	file_text := ""
	data, read_ok := os.read_entire_file(filepath, context.allocator)
	if read_ok == os.General_Error.None {
		file_text = string(data)
	}
	defer if read_ok == os.General_Error.None do delete(data)
	lines: [dynamic]string
	defer delete(lines)
	if len(file_text) > 0 {
		raw_lines := strings.split_lines(file_text)
		defer delete(raw_lines)
		for line in raw_lines {
			append(&lines, line)
		}
	}
	for len(lines) <= target_index {
		append(&lines, "")
	}
	lines[target_index] = new_text
	new_file_text, join_err := strings.join(lines[:], "\n")
	if join_err != .None {
		return .ERROR_PARSE_FILE_AND_JOIN_CONTENT_IN_FILE_SET
	}
	defer delete(new_file_text)
	write_ok := os.write_entire_file(filepath, transmute([]u8)new_file_text)
	if write_ok != os.General_Error.None {
		return .ERROR_FAILED_TO_WRITE_FILE_IN_FILE_SET
	}
	return
}

file_get :: proc(filename: string, index: int) -> (ret_str: string, code: types.exit_codes) {
	if index < 0 {
		return "", .INDEX_OUT_OF_BOUNDS_IN_FILE_GET
	}
	data, read_ok := os.read_entire_file(filename, context.allocator)
	if read_ok != os.General_Error.None {
		return "", .ERROR_READING_FILE_IN_FILE_GET
	}
	defer delete(data)
	lines := strings.split_lines(string(data))
	defer delete(lines)
	if index >= len(lines) {
		return "", .INDEX_IS_GREATER_THAN_FILE_LENGTH
	}
	ret_str = strings.clone(lines[index])
	return
}

file_exists :: proc(filename: string) -> (ret_bl: bool, code: types.exit_codes) {
	ret_bl = os.exists(filename)
	return
}

file_length :: proc(filepath: string) -> (ret_int: int, code: types.exit_codes) {
	data, read_ok := os.read_entire_file(filepath, context.allocator)
	if read_ok != os.General_Error.None {
		return 0, .ERROR_READING_FILE_TO_GET_FILE_LENGTH
	}
	defer delete(data)
	text := strings.trim_right_space(string(data))
	if len(text) == 0 {
		return 0, .OK
	}
	ret_int = strings.count(text, "\n") + 1
	return
}
