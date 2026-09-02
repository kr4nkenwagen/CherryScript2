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
		data, err := os.read_entire_file("/dev/stdin", context.allocator)
		if err != nil {
			fmt.eprintln("[ERR] failed to read stdin")
			return .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_FROM_FILE
		}
		formatted := format_source(string(data)) or_return
		fmt.print(formatted)
		return
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

	out: strings.Builder
	strings.builder_init(&out)
	line: strings.Builder
	strings.builder_init(&line)
	flush_line :: proc(out: ^strings.Builder, line: ^strings.Builder, indent: int) {
		for i := 0; i < indent; i += 1 {
			strings.write_string(out, "    ")
		}
		strings.write_string(out, strings.to_string(line^))
		strings.write_rune(out, '\n')
		strings.builder_reset(line)
	}

	indent := 0
	paren_depth := 0
	first_on_line := true
	prev_type: types.token_type_t = types.token_type_t(nil)

	for i := 0; i < len(tokens.list); i += 1 {
		tok := tokens.list[i]
		if tok == nil do continue
		t := tok.type

		if t == .END_OF_FILE do continue

		#partial switch t {
		case .TERMINATOR, .SEMICOLON:
			if paren_depth > 0 {
				strings.write_string(&line, ";")
				prev_type = t
				if !first_on_line do first_on_line = false
				continue
			}
			if !first_on_line {
				flush_line(&out, &line, indent)
				first_on_line = true
				prev_type = types.token_type_t(nil)
			}

		case .LEFT_BRACE:
			if !first_on_line && needs_space(prev_type, .LEFT_BRACE) {
				strings.write_rune(&line, ' ')
			}
			strings.write_string(&line, "{")
			flush_line(&out, &line, indent)
			indent += 1
			first_on_line = true
			prev_type = types.token_type_t(nil)

		case .RIGHT_BRACE:
			if !first_on_line {
				flush_line(&out, &line, indent)
			}
			indent -= 1
			if indent < 0 do indent = 0
			strings.write_string(&line, "}")
			// Keep `} elif ...` / `} else ...` on the same line.
			next := types.token_type_t(nil)
			if i + 1 < len(tokens.list) && tokens.list[i + 1] != nil {
				next = tokens.list[i + 1].type
			}
			if next == .ELSE_IF || next == .ELSE {
				first_on_line = false
				prev_type = .RIGHT_BRACE
			} else {
				flush_line(&out, &line, indent)
				first_on_line = true
				prev_type = types.token_type_t(nil)
			}

		case:
			if !first_on_line {
				if needs_space(prev_type, t) {
					strings.write_rune(&line, ' ')
				}
				write_token_literal(tok, &line)
			} else {
				write_token_literal(tok, &line)
				first_on_line = false
			}
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
		flush_line(&out, &line, indent)
	}

	formatted = strings.to_string(out)
	return
}

