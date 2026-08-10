package source_code

import "../sys"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"

create :: proc(content: string) -> (^types.source_code_t, types.exit_codes) {
	src := new(types.source_code_t)
	if src == nil {
		return nil, .MEMORY_ALLOCATION_FAILED
	}
	src.content = content
	src.length = len(src.content)
	src.pointer = -1
	src.line = 1
	src.column = 0
	src.is_at_end = false
	return src, .OK
}

from_file :: proc(file: string) -> (^types.source_code_t, types.exit_codes) {
	data, err := os.read_entire_file(file, context.allocator)
	if err != nil {
		return nil, types.exit_codes.FAILED_TO_READ_SOURCE_CODE_FILE
	}
	src, src_err := create(string(data))
	if sys.is_error(src_err) {
		return nil, src_err
	}
	src.location = os.dir(file)
	return src, .OK
}

from_repl :: proc(line: string) -> (^types.source_code_t, types.exit_codes) {
	return create(line)
}

import_file :: proc(target: ^types.source_code_t, src_path: string) -> types.exit_codes {
	src_path := src_path
	if len(src_path) > 0 && src_path[0] != '/' && !os.exists(src_path) {
		src_path = fmt.tprintf("%s/%s", target.location, src_path)
	}
	for i in target.included_sources {
		if i == src_path {
			return .OK
		}
	}
	append(&target.included_sources, src_path)
	file_data, err := os.read_entire_file(src_path, context.allocator)
	if err != nil {
		return .FAILED_TO_READ_SOURCE_CODE_FILE
	}
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
	return .OK
}

advance :: proc(src: ^types.source_code_t, count: int = 1) -> (rune, types.exit_codes) {
	if src == nil {
		return 0, .OBJECT_IS_NIL
	}
	for i := 0; i < count; i += 1 {
		if src.is_at_end {
			return 0, .EOF_IN_SOURCE_CODE_REACHED
		}
		src.pointer += 1
		if src.pointer >= src.length {
			src.is_at_end = true
			return 0, .EOF_IN_SOURCE_CODE_REACHED
		}
		src.column += 1
		if src.content[src.pointer] == '\n' {
			src.line += 1
			src.column = 0
		}
	}
	return rune(src.content[src.pointer]), .OK
}

peek :: proc(src: ^types.source_code_t, distance: int = 0) -> (rune, types.exit_codes) {
	if src == nil {
		return 0, .OBJECT_IS_NIL
	}
	if src.pointer + distance >= src.length || src.pointer + distance < 0 {
		return 0, .PEEK_OUT_OF_BOUNDS
	}
	return rune(src.content[src.pointer + distance]), .OK
}

remove :: proc(src: ^types.source_code_t) -> types.exit_codes {
	if src == nil {
		return .OBJECT_IS_NIL
	}
	delete(src.content)
	free(src)
	return .OK
}
