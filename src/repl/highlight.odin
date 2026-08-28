package repl

import "../sys"
import "core:strings"

KEYWORDS :: []string{
	"break",
	"const",
	"continue",
	"else",
	"elif",
	"err",
	"exists",
	"for",
	"false",
	"fn",
	"if",
	"null",
	"out",
	"len",
	"println",
	"print",
	"return",
	"rm",
	"remove",
	"true",
	"var",
	"time",
	"in",
	"sleep",
	"key",
	"clr",
	"global",
	"json",
	"http",
	"terminal",
	"string",
	"math",
}

Paint :: struct {
	b:     strings.Builder,
	color: string,
}

paint_line :: proc(ed: ^Editor) -> string {
	p: Paint
	p.b = strings.builder_make(context.temp_allocator)
	emit(&p, sys.CLR_CYAN, "> ")
	emit(&p, "", "")
	text := ed.line[:]
	i := 0
	for i < len(text) {
		ch := text[i]
		if ch == ' ' || ch == '\t' {
			emit(&p, "", string(text[i:i + 1]))
			i += 1
			continue
		}
		if ch == '"' || ch == '\'' {
			end, _ := scan_string(text, i)
			emit(&p, sys.CLR_AMBER, string(text[i:end]))
			i = end
		} else if ch == '#' {
			end := scan_comment(text, i)
			emit(&p, sys.CLR_MUTED, string(text[i:end]))
			i = end
		} else if is_digit(ch) || (ch == '.' && i + 1 < len(text) && is_digit(text[i + 1])) || (ch == '-' && is_unary_minus(text, i)) {
			end := scan_number(text, i)
			emit(&p, sys.CLR_GREEN, string(text[i:end]))
			i = end
		} else if is_word_start(ch) {
			end := scan_word(text, i)
			word := string(text[i:end])
			if is_keyword(text, i, word) {
				emit(&p, sys.CLR_TITLE, word)
			} else {
				emit(&p, "", word)
			}
			i = end
		} else if ch == '&' && i + 1 < len(text) && text[i + 1] == '&' {
			emit(&p, sys.CLR_TITLE, "&&")
			i += 2
		} else if ch == '|' && i + 1 < len(text) && text[i + 1] == '|' {
			emit(&p, sys.CLR_TITLE, "||")
			i += 2
		} else if ch == '!' && i + 1 < len(text) && text[i + 1] == '!' {
			emit(&p, sys.CLR_TITLE, "!!")
			i += 2
		} else if ch == '$' || ch == '@' {
			emit(&p, sys.CLR_TITLE, string(text[i:i + 1]))
			i += 1
		} else {
			emit(&p, "", string(text[i:i + 1]))
			i += 1
		}
	}
	emit(&p, "", "")
	return strings.to_string(p.b)
}

emit :: proc(p: ^Paint, color: string, text: string) {
	if p.color != color {
		p.color = color
		if color == "" {
			strings.write_string(&p.b, sys.CLR_RESET)
		} else {
			strings.write_string(&p.b, color)
		}
	}
	strings.write_string(&p.b, text)
}

is_digit :: proc(ch: u8) -> bool {
	return ch >= '0' && ch <= '9'
}

is_word_start :: proc(ch: u8) -> bool {
	return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || ch == '_'
}

is_end_of_word :: proc(ch: u8) -> bool {
	switch ch {
	case '\n', '\t', ' ', ';', '[', ']', '(', ')', '{', '}', ':', '=', '+', '-', '/', '*', '!', '<', '>', '.', ',':
		return true
	}
	return false
}

scan_string :: proc(text: []u8, start: int) -> (end: int, closed: bool) {
	quote := text[start]
	i := start + 1
	escaped := false
	for i < len(text) {
		c := text[i]
		if escaped {
			escaped = false
		} else if c == '\\' {
			escaped = true
		} else if c == quote {
			i += 1
			return i, true
		}
		i += 1
	}
	return i, false
}

scan_comment :: proc(text: []u8, start: int) -> int {
	i := start + 1
	for i < len(text) {
		if text[i] == '\n' || text[i] == '#' do break
		i += 1
	}
	return i
}

scan_number :: proc(text: []u8, start: int) -> int {
	i := start
	if text[i] == '-' || text[i] == '.' {
		i += 1
	}
	for i < len(text) && is_digit(text[i]) do i += 1
	if i < len(text) && text[i] == '.' && (i + 1 >= len(text) || text[i + 1] != '.') {
		i += 1
		for i < len(text) && is_digit(text[i]) do i += 1
	}
	return i
}

is_unary_minus :: proc(text: []u8, i: int) -> bool {
	if i + 1 >= len(text) do return false
	next := text[i + 1]
	is_number_start :=
		is_digit(next) || (next == '.' && i + 2 < len(text) && is_digit(text[i + 2]))
	if !is_number_start do return false
	if i == 0 do return true
	prev := text[i - 1]
	is_operand :=
		(prev >= 'a' && prev <= 'z') || (prev >= 'A' && prev <= 'Z') || prev == '_' ||
		is_digit(prev) || prev == ')' || prev == ']' || prev == '}'
	return !is_operand
}

scan_word :: proc(text: []u8, start: int) -> int {
	i := start
	for i < len(text) && !is_end_of_word(text[i]) do i += 1
	return i
}

is_keyword :: proc(text: []u8, start: int, word: string) -> bool {
	if start > 0 {
		prev := text[start - 1]
		if (prev >= 'a' && prev <= 'z') || (prev >= 'A' && prev <= 'Z') || prev == '.' do return false
	}
	for k in KEYWORDS {
		if strings.equal_fold(word, k) do return true
	}
	return false
}