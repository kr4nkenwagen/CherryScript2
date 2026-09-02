package format

import "../scanner"
import "../source_code"
import "../token_list"
import "../types"
import "core:fmt"
import "core:os"
import "core:strings"


run :: proc(source_file_suffix: string) -> (code: types.exit_codes) {
	in_place := false
	var_idx := 1
	if len(os.args) > var_idx && (os.args[var_idx] == "format" || os.args[var_idx] == "-format") {
		var_idx += 1
	}
	files: [dynamic]string
	if len(os.args) > var_idx && (os.args[var_idx] == "-w" || os.args[var_idx] == "--write") {
		in_place = true
		var_idx += 1
	}
	for var_idx < len(os.args) {
		if strings.has_suffix(os.args[var_idx], source_file_suffix) {
			append(&files, os.args[var_idx])
		}
		var_idx += 1
	}

	read_stdin := len(files) == 0

	if read_stdin {
		b := strings.Builder{}
		strings.builder_init(&b)
		buf: [4096]byte
		for {
			n, rerr := os.read(os.stdin, buf[:])
			if n > 0 {
				strings.write_bytes(&b, buf[:n])
			}
			if n == 0 {
				break
			}
			if rerr != nil {
				fmt.eprintln("[ERR] failed to read stdin")
				return .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_FROM_FILE
			}
		}
		formatted := format_source(strings.to_string(b)) or_return
		fmt.print(formatted)
		return
	}

	for file_path in files {
		data, rerr := os.read_entire_file(file_path, context.allocator)
		if rerr != nil {
			fmt.eprintln("[ERR] failed to read file: %s", file_path)
			delete(data)
			return .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_FROM_FILE
		}
		formatted := format_source(string(data)) or_return
		if in_place {
			if werr := os.write_entire_file(file_path, formatted); werr != nil {
				fmt.eprintln("[ERR] failed to write file: %s", file_path)
				return .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_FROM_FILE
			}
		} else {
			fmt.print(formatted)
		}
	}
	return
}

is_tight_before :: proc(t: types.token_type_t) -> bool {
	#partial switch t {
	case .RIGHT_PAREN,
	     .RIGHT_BRACKET,
	     .COMMA,
	     .SEMICOLON,
	     .TERMINATOR,
	     .DOT,
	     .COLON,
	     .COLON_HAT,
	     .LEFT_PAREN,
	     .LEFT_BRACKET,
	     .LEFT_ARROW,
	     .RIGHT_ARROW:
		return true
	}
	return false
}

is_tight_after :: proc(t: types.token_type_t) -> bool {
	#partial switch t {
	case .LEFT_PAREN,
	     .LEFT_BRACKET,
	     .DOT,
	     .COLON,
	     .COLON_HAT,
	     .LEFT_ARROW,
	     .RIGHT_ARROW,
	     .BANG,
	     .AT,
	     .EXECUTE:
		return true
	}
	return false
}

needs_space :: proc(prev: types.token_type_t, curr: types.token_type_t) -> bool {
	if is_tight_before(curr) do return false
	if is_tight_after(prev) do return false
	return true
}

escape_string_literal :: proc(content: string, b: ^strings.Builder) {
	for i := 0; i < len(content); i += 1 {
		c := content[i]
		switch c {
		case '\n':
			strings.write_string(b, "\\n")
		case '\t':
			strings.write_string(b, "\\t")
		case '\r':
			strings.write_string(b, "\\r")
		case 0:
			strings.write_string(b, "\\0")
		case '\\':
			strings.write_string(b, "\\\\")
		case '"':
			strings.write_string(b, "\\\"")
		case:
			strings.write_rune(b, rune(c))
		}
	}
}

write_token_literal :: proc(tok: ^types.token_t, b: ^strings.Builder) {
	if tok.type == .STRING_WRAPPER {
		strings.write_string(b, "\"")
		escape_string_literal(tok.literal, b)
		strings.write_string(b, "\"")
		return
	}
	strings.write_string(b, tok.literal)
}

format_source :: proc(content: string) -> (formatted: string, code: types.exit_codes) {
	src := source_code.create(content) or_return
	defer source_code.remove(src)
	scanner.order_symbols_by_literal_length()
	tokens := scanner.run(src) or_return
	defer token_list.remove(tokens)
	comments := capture_comments(src.content)
	defer delete(comments)
	ci := 0
	out: strings.Builder
	strings.builder_init(&out)
	line: strings.Builder
	strings.builder_init(&line)
	line_src_last := -1
	last_col := -1
	indent := 0
	paren_depth := 0
	first_on_line := true
	prev_type: types.token_type_t = types.token_type_t(nil)

	write_indent :: proc(out: ^strings.Builder, indent: int) {
		for i := 0; i < indent; i += 1 {
			strings.write_string(out, "    ")
		}
	}

	emit_leading :: proc(
		comments: [dynamic]comment_t,
		ci: ^int,
		out: ^strings.Builder,
		indent: int,
		target_line: int,
	) {
		for ci^ < len(comments) {
			c := comments[ci^]
			if c.line >= target_line do break
			write_indent(out, indent)
			strings.write_string(out, c.text)
			strings.write_rune(out, '\n')
			ci^ += 1
		}
	}

	append_trailing :: proc(
		comments: [dynamic]comment_t,
		ci: ^int,
		line: ^strings.Builder,
		line_src_last: int,
		last_col: int,
	) {
		if ci^ < len(comments) {
			c := comments[ci^]
			if c.line == line_src_last && c.column > last_col {
				if strings.builder_len(line^) > 0 {
					strings.write_string(line, "  ")
				}
				strings.write_string(line, c.text)
				ci^ += 1
			}
		}
	}

	flush_line :: proc(
		out: ^strings.Builder,
		line: ^strings.Builder,
		indent: int,
		comments: [dynamic]comment_t,
		ci: ^int,
		line_src_last: int,
		last_col: int,
	) {
		append_trailing(comments, ci, line, line_src_last, last_col)
		for i := 0; i < indent; i += 1 {
			strings.write_string(out, "    ")
		}
		strings.write_string(out, strings.to_string(line^))
		strings.write_rune(out, '\n')
		strings.builder_reset(line)
	}
	for i := 0; i < len(tokens.list); i += 1 {
		tok := tokens.list[i]
		if tok == nil do continue
		t := tok.type
		if t == .END_OF_FILE {
			continue
		}
		#partial switch t {
		case .TERMINATOR, .SEMICOLON:
			if paren_depth > 0 {
				strings.write_string(&line, ";")
				prev_type = t
				if !first_on_line do first_on_line = false
				continue
			}
			if !first_on_line {
				flush_line(&out, &line, indent, comments, &ci, line_src_last, last_col)
				first_on_line = true
				prev_type = types.token_type_t(nil)
				line_src_last = -1
				last_col = -1
			}

		case .LEFT_BRACE:
			if !first_on_line && needs_space(prev_type, .LEFT_BRACE) {
				strings.write_rune(&line, ' ')
			}
			strings.write_string(&line, "{")
			line_src_last = tok.line
			last_col = tok.column + 1
			flush_line(&out, &line, indent, comments, &ci, line_src_last, last_col)
			indent += 1
			first_on_line = true
			prev_type = types.token_type_t(nil)
			line_src_last = -1
			last_col = -1
		case .RIGHT_BRACE:
			if !first_on_line {
				emit_leading(comments, &ci, &out, indent, tok.line)
				flush_line(&out, &line, indent, comments, &ci, line_src_last, last_col)
			}
			indent -= 1
			if indent < 0 do indent = 0
			strings.write_string(&line, "}")
			line_src_last = tok.line
			last_col = tok.column + 1
			next := types.token_type_t(nil)
			if i + 1 < len(tokens.list) && tokens.list[i + 1] != nil {
				next = tokens.list[i + 1].type
			}
			if next == .ELSE_IF || next == .ELSE {
				first_on_line = false
				prev_type = .RIGHT_BRACE
			} else {
				flush_line(&out, &line, indent, comments, &ci, line_src_last, last_col)
				first_on_line = true
				prev_type = types.token_type_t(nil)
				line_src_last = -1
				last_col = -1
			}
		case:
			if first_on_line {
				emit_leading(comments, &ci, &out, indent, tok.line)
			}
			if !first_on_line {
				if needs_space(prev_type, t) {
					strings.write_rune(&line, ' ')
				}
				write_token_literal(tok, &line)
			} else {
				write_token_literal(tok, &line)
				first_on_line = false
			}
			line_src_last = tok.line
			last_col = tok.column + len(tok.literal)
			prev_type = t

			#partial switch t {
			case .LEFT_PAREN, .LEFT_BRACKET:
				paren_depth += 1
			case .RIGHT_PAREN, .RIGHT_BRACKET:
				if paren_depth > 0 do paren_depth -= 1
			}
		}
	}
	if !first_on_line {
		flush_line(&out, &line, indent, comments, &ci, line_src_last, last_col)
	}
	emit_leading(comments, &ci, &out, indent, max(int))
	formatted = strings.to_string(out)
	return
}
