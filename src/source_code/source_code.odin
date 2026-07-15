package source_code

import "../types"
import "core:os"
import "core:strings"


create :: proc(content: string) -> ^types.source_code_t {
	src := new(types.source_code_t)
	src.content = content
	src.length = len(src.content)
	src.pointer = -1
	src.line = 0
	src.column = 0
	src.is_at_end = false
	return src
}

from_file :: proc(file: string) -> ^types.source_code_t {
	data, err := os.read_entire_file(file, context.allocator)
	if err != nil {
		return nil
	}
	return create(string(data))
}

from_repl :: proc(line: string) -> ^types.source_code_t {
	return create(line)
}

import_file :: proc(target: ^types.source_code_t, src_path: string) {
	file_data, err := os.read_entire_file(src_path, context.allocator)
	if err != nil {
		return
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
}

advance :: proc(src: ^types.source_code_t) -> rune {
	if src == nil {
		return 0
	}
	src.pointer += 1
	if src.pointer == src.length {
		src.is_at_end = true
		return 0
	}
	src.column += 1
	if src.content[src.pointer] == '\n' {
		src.line += 1
		src.column = 0
	}
	return rune(src.content[src.pointer])
}

peek :: proc(src: ^types.source_code_t, distance := int(0)) -> rune {
	if src == nil || src.pointer + distance >= src.length || src.pointer + distance < 0 {
		return 0
	}
	return rune(src.content[src.pointer + distance])
}

remove :: proc(src: ^types.source_code_t) {
	if src == nil {
		return
	}
	delete(src.content)
	free(src)
}
