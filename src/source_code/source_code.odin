package source_code

import "../types"
import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:strings"

create :: proc(content: string) -> (src: ^types.source_code_t, code: types.exit_codes) {
	src = new(types.source_code_t)
	if src == nil {
		return nil, .MEMORY_ALLOCATION_FAILED_IN_CREATE_SOURCE_CODE
	}
	src.content = content
	src.length = len(src.content)
	src.pointer = -1
	src.line = 1
	src.column = 1
	src.is_at_end = false
	return
}

from_file :: proc(file: string) -> (src: ^types.source_code_t, code: types.exit_codes) {
	data, err := os.read_entire_file(file, context.allocator)
	if err != nil {
		return nil, .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_FROM_FILE
	}
	src = create(string(data)) or_return
	wd, _ := os.get_working_directory(context.allocator)
	defer delete(wd, context.allocator)
	file_dir := filepath.dir(file)
	src.location, _ = filepath.join([]string{wd, file_dir}, context.allocator)
	return
}

from_repl :: proc(line: string) -> (src: ^types.source_code_t, code: types.exit_codes) {
	line := strings.concatenate({line, ";"})
	src = create(line) or_return
	return
}

get_cherry_files_in_dir :: proc(
	src_path: string,
) -> (
	paths: [dynamic]string,
	code: types.exit_codes,
) {
	if os.is_dir(src_path) {
		f, err := os.open(src_path)
		if err != os.ERROR_NONE {
			return nil, .FAILED_TO_OPEN_DIR_FILE_IN_SOURCE_CODE_GET_CHERRY_FILES_IN_DIR
		}
		file_infos, read_err := os.read_dir(f, -1, context.allocator)
		if read_err != os.ERROR_NONE {
			return nil, .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_GET_CHERRY_FILES_IN_DIR
		}
		for info in file_infos {
			if strings.has_suffix(info.name, ".cherry") {
				append(&paths, info.fullpath)
			}
		}
	} else {
		append(&paths, src_path)
	}
	return
}

import_file :: proc(target: ^types.source_code_t, src_path: string) -> (code: types.exit_codes) {
	src_path := src_path
	if len(src_path) > 0 && src_path[0] != '/' && !os.exists(src_path) do src_path = fmt.tprintf("%s/%s", target.location, src_path)
	paths := get_cherry_files_in_dir(src_path) or_return
	for path in paths {
		path := path
		if os.is_dir(path) do continue

		for i in target.included_sources {
			if i == path do return
		}
		append(&target.included_sources, path)
		file_data, err := os.read_entire_file(path, context.allocator)
		if err != nil do return .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_IMPORT_FILE
		defer delete(file_data)
		obj_src := string(file_data)
		b: strings.Builder
		strings.builder_init(&b)
		strings.builder_grow(&b, len(target.content) + len(obj_src) + 2)
		strings.write_string(&b, target.content[:target.pointer])
		strings.write_byte(&b, '\n')
		strings.write_string(&b, obj_src)
		strings.write_byte(&b, '\n')
		strings.write_string(&b, target.content[target.pointer:])
		target.content = strings.to_string(b)
		target.length = len(target.content)
	}
	return
}

advance :: proc(
	src: ^types.source_code_t,
	count: int = 1,
) -> (
	char: rune,
	code: types.exit_codes,
) {
	if src == nil do return 0, .OBJECT_IS_NIL_IN_SOURCE_CODE_ADVANCE
	for i := 0; i < count; i += 1 {
		if src.is_at_end do return 0, .EOF_ALREADY_TRIGGERED_REACHED_IN_SOURCE_CODE_ADVANCE
		src.pointer += 1
		if src.pointer >= src.length {
			src.is_at_end = true
			return 0, .EOF_IN_SOURCE_CODE_REACHED_IN_SOURCE_CODE_ADVANCE
		}
		src.column += 1
		if src.content[src.pointer] == '\n' {
			src.line += 1
			src.column = 1
		}
	}
	char = rune(src.content[src.pointer])
	return
}

peek :: proc(
	src: ^types.source_code_t,
	distance: int = 0,
) -> (
	char: rune,
	code: types.exit_codes,
) {
	if src == nil do return 0, .OBJECT_IS_NIL_IN_SOURCE_CODE_PEEK
	if src.pointer + distance >= src.length || src.pointer + distance < 0 do return 0, .OUT_OF_BOUNDS_IN_SOURCE_CODE_PEEK
	char = rune(src.content[src.pointer + distance])
	return
}

remove :: proc(src: ^types.source_code_t) -> (code: types.exit_codes) {
	if src == nil do return .OBJECT_IS_NIL_IN_SOURCE_CODE_REMOVE
	delete(src.content)
	free(src)
	return
}
