package repl

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/posix"

HISTORY_MAX :: 1000
HISTORY_FILE_NAME :: ".cherry_history"

Editor :: struct {
	line:     [dynamic]u8,
	cursor:   int,
	history:  [dynamic]string,
	hist_idx: int,
	draft:    string,
}

destroy_editor :: proc(ed: ^Editor) {
	for entry in ed.history do delete(entry)
	delete(ed.history)
	delete(ed.line)
	delete(ed.draft)
}

history_file_path :: proc() -> string {
	home := os.get_env("HOME", context.temp_allocator)
	if len(home) == 0 do return ""
	return strings.join({home, HISTORY_FILE_NAME}, "/", context.temp_allocator)
}

load_history :: proc() -> [dynamic]string {
	history: [dynamic]string
	path := history_file_path()
	if len(path) == 0 || !os.exists(path) do return history
	data, err := os.read_entire_file(path, context.allocator)
	if err != nil do return history
	defer delete(data)
	lines: [dynamic]string
	defer delete(lines)
	text := string(data)
	pos := 0
	for i := 0; i <= len(text); i += 1 {
		if i == len(text) || text[i] == '\n' {
			entry := strings.trim(text[pos:i], "\r")
			if len(entry) > 0 do append(&lines, strings.clone(entry))
			pos = i + 1
		}
	}
	start := len(lines) > HISTORY_MAX ? len(lines) - HISTORY_MAX : 0
	for i in start ..< len(lines) do append(&history, lines[i])
	if start > 0 do trim_history_file(path, history[:])
	for i in 0 ..< start do delete(lines[i])
	return history
}

trim_history_file :: proc(path: string, history: []string) {
	f, err := os.open(path, {.Write, .Trunc, .Create})
	if err != nil do return
	defer os.close(f)
	for line in history {
		os.write_string(f, line)
		os.write_string(f, "\n")
	}
}

append_history :: proc(history: ^[dynamic]string, line: string) {
	trimmed := strings.trim_space(line)
	if len(trimmed) == 0 || trimmed == "exit" || trimmed == "quit" do return
	if len(history^) > 0 && history^[len(history^) - 1] == trimmed do return
	append(history, strings.clone(trimmed))
	if len(history^) > HISTORY_MAX {
		removed := history^[0]
		ordered_remove(history, 0)
		delete(removed)
	}
	path := history_file_path()
	if len(path) == 0 do return
	f, err := os.open(path, {.Write, .Append, .Create})
	if err != nil do return
	defer os.close(f)
	os.write_string(f, trimmed)
	os.write_string(f, "\n")
}

read_line :: proc(ed: ^Editor) -> (line: string, eof: bool) {
	fd: posix.FD = posix.STDIN_FILENO
	orig: posix.termios
	has_termios := posix.tcgetattr(fd, &orig) == .OK
	if has_termios {
		set_mode(fd, edit_mode(orig))
	}
	defer if has_termios {
		posix.tcsetattr(fd, .TCSANOW, &orig)
	}
	defer {
		clear(&ed.line)
		ed.cursor = 0
		ed.hist_idx = len(ed.history)
	}
	redraw(ed)
	for {
		buf: [1]byte
		n, err := os.read(os.stdin, buf[:])
		if err != nil || n <= 0 {
				fmt.println()
			return "", true
		}
		ch := buf[0]
		switch ch {
		case 0x0d, 0x0a:
			fmt.println()
			if len(ed.line) > 0 {
				append_history(&ed.history, string(ed.line[:]))
			}
			trimmed := strings.trim_space(string(ed.line[:]))
			if len(trimmed) > 0 {
				line = strings.clone_from_bytes(ed.line[:])
			}
			return line, false
		case 0x03:
			clear(&ed.line)
			ed.cursor = 0
			fmt.println("^C")
			redraw(ed)
		case 0x04:
			if len(ed.line) == 0 {
				fmt.println()
				return "", true
			}
		case 0x15:
			for ed.cursor > 0 {
				erase_at(ed, ed.cursor - 1)
				ed.cursor -= 1
			}
			redraw(ed)
		case 0x0b:
			for ed.cursor < len(ed.line) {
				erase_at(ed, ed.cursor)
			}
			redraw(ed)
		case 0x17:
			kill_word(ed)
		case 0x7f, 0x08:
			if ed.cursor > 0 {
				erase_at(ed, ed.cursor - 1)
				ed.cursor -= 1
				redraw(ed)
			}
		case 0x1b:
			if has_termios do handle_escape(ed)
		case 0x20 ..= 0x7e:
			insert_char(ed, ch)
		}
	}
	return "", true
}

edit_mode :: proc(orig: posix.termios) -> posix.termios {
	mode := orig
	mode.c_lflag -= {.ICANON, .ECHO}
	mode.c_cc[.VMIN] = 1
	mode.c_cc[.VTIME] = 0
	return mode
}

set_mode :: proc(fd: posix.FD, mode: posix.termios) {
	m := mode
	posix.tcsetattr(fd, .TCSANOW, &m)
}

read_byte :: proc() -> (ch: u8, ok: bool) {
	buf: [1]byte
	n, err := os.read(os.stdin, buf[:])
	if err != nil || n <= 0 do return 0, false
	return buf[0], true
}

handle_escape :: proc(ed: ^Editor) {
	fd: posix.FD = posix.STDIN_FILENO
	orig: posix.termios
	if posix.tcgetattr(fd, &orig) != .OK do return
	timed := orig
	timed.c_lflag -= {.ICANON, .ECHO}
	timed.c_cc[.VMIN] = 0
	timed.c_cc[.VTIME] = 1
	set_mode(fd, timed)
	defer set_mode(fd, edit_mode(orig))
	b1, ok1 := read_byte()
	if !ok1 do return
	if b1 != '[' do return
	b2, ok2 := read_byte()
	if !ok2 do return
	switch b2 {
	case 'A':
		history_previous(ed)
	case 'B':
		history_next(ed)
	case 'C':
		move_cursor(ed, 1)
	case 'D':
		move_cursor(ed, -1)
	case 'H':
		move_cursor(ed, -ed.cursor)
	case 'F':
		move_cursor(ed, len(ed.line) - ed.cursor)
	case '1', '3', '4', '7', '8':
		b3, ok3 := read_byte()
		if ok3 && b3 == '~' {
			switch b2 {
			case '1', '7', '8':
				move_cursor(ed, -ed.cursor)
			case '4':
				move_cursor(ed, len(ed.line) - ed.cursor)
			case '3':
				erase_at(ed, ed.cursor)
			}
		}
	}
}

redraw :: proc(ed: ^Editor) {
	fmt.printf("\r\e[2K%s\e[%dG", paint_line(ed), ed.cursor + 3)
}

set_line :: proc(ed: ^Editor, text: string) {
	clear(&ed.line)
	for i in 0 ..< len(text) do append(&ed.line, text[i])
	ed.cursor = len(text)
	redraw(ed)
}

insert_char :: proc(ed: ^Editor, ch: u8) {
	if ed.cursor >= len(ed.line) {
		append(&ed.line, ch)
	} else {
		length := len(ed.line)
		append(&ed.line, 0)
		copy(ed.line[ed.cursor + 1:], ed.line[ed.cursor:length])
		ed.line[ed.cursor] = ch
	}
	ed.cursor += 1
	redraw(ed)
}

erase_at :: proc(ed: ^Editor, index: int) {
	if index < 0 || index >= len(ed.line) do return
	copy(ed.line[index:], ed.line[index + 1:])
	pop(&ed.line)
}

kill_word :: proc(ed: ^Editor) {
	start := ed.cursor
	for start > 0 && ed.line[start - 1] == ' ' do start -= 1
	for start > 0 && ed.line[start - 1] != ' ' do start -= 1
	if start == ed.cursor do return
	for start < ed.cursor {
		erase_at(ed, start)
	}
	ed.cursor = start
	redraw(ed)
}

move_cursor :: proc(ed: ^Editor, delta: int) {
	ed.cursor = clamp(ed.cursor + delta, 0, len(ed.line))
	redraw(ed)
}

history_previous :: proc(ed: ^Editor) {
	if len(ed.history) == 0 do return
	if ed.hist_idx == len(ed.history) {
		delete(ed.draft)
		ed.draft = strings.clone_from_bytes(ed.line[:])
	}
	if ed.hist_idx > 0 {
		ed.hist_idx -= 1
		set_line(ed, ed.history[ed.hist_idx])
	}
}

history_next :: proc(ed: ^Editor) {
	if ed.hist_idx < len(ed.history) {
		ed.hist_idx += 1
		if ed.hist_idx == len(ed.history) {
			set_line(ed, ed.draft)
		} else {
			set_line(ed, ed.history[ed.hist_idx])
		}
	}
}