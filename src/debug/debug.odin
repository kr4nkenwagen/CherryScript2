package debug

import "../types"
import "../vm"
import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/posix"

g_output_log: [dynamic]string
g_snapshots: ^types.debug_snapshot_collection_t
g_source_code: ^types.source_code_t

// UI Palette
CLR_RESET :: "\e[0m"
CLR_BOLD :: "\e[1m"
CLR_BORDER :: "\e[38;5;238m" // Dark gray border
CLR_TITLE :: "\e[38;5;204m" // Cherry Pink
CLR_CYAN :: "\e[38;5;75m" // Muted Cyan
CLR_AMBER :: "\e[38;5;215m" // Soft Amber
CLR_GREEN :: "\e[38;5;114m" // Pastel Green
CLR_TEXT :: "\e[38;5;252m" // Crisp Off-White
CLR_MUTED :: "\e[38;5;243m" // Subdued Gray
CLR_TYPE :: "\e[38;5;141m" // Lavender/Purple for Types
CLR_CONST :: "\e[38;5;220m" // Gold for Const
CLR_TOKEN_HL :: "\e[7;1m" // Inverse + Bold for Token Highlight

winsize :: struct {
	ws_row:    c.ushort,
	ws_col:    c.ushort,
	ws_xpixel: c.ushort,
	ws_ypixel: c.ushort,
}

when ODIN_OS == .Darwin {
	TIOCGWINSZ: c.ulong : 0x40087468
} else {
	TIOCGWINSZ: c.ulong : 0x5413
}

foreign import libc "system:c"

@(default_calling_convention = "c")
foreign libc {
	ioctl :: proc(fd: c.int, request: c.ulong, arg: ^winsize) -> c.int ---
}

get_terminal_size :: proc(raw_fd: posix.FD) -> (cols: int, rows: int) {
	ws: winsize
	if ioctl(c.int(raw_fd), TIOCGWINSZ, &ws) != -1 {
		cols = ws.ws_col > 30 ? int(ws.ws_col) : 100
		rows = ws.ws_row > 4 ? int(ws.ws_row) : 24
		return
	}
	return 100, 24
}

pad_right :: proc(s: string, target_len: int) -> string {
	if target_len <= 0 do return ""
	if len(s) >= target_len {
		return s[:target_len]
	}
	padding := strings.repeat(" ", target_len - len(s))
	defer delete(padding)
	return fmt.tprintf("%s%s", s, padding)
}

get_type_badge :: proc(type: types.object_type_t) -> string {
	#partial switch type {
	case .INT:
		return "INT "
	case .FLOAT:
		return "FLT "
	case .STRING:
		return "STR "
	case .ARRAY:
		return "ARR "
	case .NULL:
		return "NUL "
	case .BOOL:
		return "BOOL"
	case .FUNCTION:
		return "FUNC"
	case .FILE:
		return "FILE"
	case:
		return "UNK "
	}
}

// Deep object data formatter guided by obj.type
format_object_t :: proc(obj: types.object_t, depth: int = 0) -> string {
	if depth > 3 {
		return "..."
	}

	#partial switch obj.type {
	case .FUNCTION:
		// Functions should not display a value
		return ""

	case .NULL:
		return "null"

	case .INT:
		#partial switch v in obj.data {
		case int:
			return fmt.tprintf("%d", v)
		case f32:
			return fmt.tprintf("%d", int(v))
		case string:
			return v
		case bool:
			return v ? "1" : "0"
		case rawptr:
			return v == nil ? "0" : fmt.tprintf("%p", v)
		case:
			return fmt.tprintf("%v", obj.data)
		}

	case .FLOAT:
		#partial switch v in obj.data {
		case f32:
			return fmt.tprintf("%.2f", v)
		case int:
			return fmt.tprintf("%.2f", f32(v))
		case string:
			return v
		case rawptr:
			return v == nil ? "0.00" : fmt.tprintf("%p", v)
		case:
			return fmt.tprintf("%v", obj.data)
		}

	case .BOOL:
		#partial switch v in obj.data {
		case bool:
			return v ? "true" : "false"
		case int:
			return v != 0 ? "true" : "false"
		case string:
			return v
		case:
			return fmt.tprintf("%v", obj.data)
		}

	case .STRING:
		#partial switch v in obj.data {
		case string:
			return fmt.tprintf("\"%s\"", v)
		case rawptr:
			if v == nil do return "\"\""
			return fmt.tprintf("\"%s\"", cast(cstring)v)
		case:
			return fmt.tprintf("\"%v\"", obj.data)
		}

	case .ARRAY:
		#partial switch v in obj.data {
		case types.object_array_t:
			sb: strings.Builder
			strings.builder_init(&sb, context.temp_allocator)
			fmt.sbprint(&sb, "[")
			max_items := 5
			for item_ptr, idx in v.value {
				if idx > 0 do fmt.sbprint(&sb, ", ")
				if idx >= max_items {
					fmt.sbprintf(&sb, "... +%d items", len(v.value) - max_items)
					break
				}
				if item_ptr == nil {
					fmt.sbprint(&sb, "null")
				} else {
					fmt.sbprint(&sb, format_object_t(item_ptr^, depth + 1))
				}
			}
			fmt.sbprint(&sb, "]")
			return strings.to_string(sb)
		case:
			return "[]"
		}
	case .FILE:
		#partial switch v in obj.data {
		case types.object_file_t:
			return fmt.tprintf("file(\"%s\")", v.name)
		case string:
			return fmt.tprintf("file(\"%s\")", v)
		case:
			return "file()"
		}

	case:
		#partial switch v in obj.data {
		case int:
			return fmt.tprintf("%d", v)
		case f32:
			return fmt.tprintf("%.2f", v)
		case string:
			return fmt.tprintf("\"%s\"", v)
		case bool:
			return v ? "true" : "false"
		case rawptr:
			return v == nil ? "null" : fmt.tprintf("%p", v)
		case:
			return "null"
		}
	}
}

// Deep clone object tree to freeze memory state at snapshot time
deep_clone_object :: proc(obj: ^types.object_t) -> ^types.object_t {
	if obj == nil do return nil
	copied := new_clone(obj^)

	#partial switch v in obj.data {
	case types.object_array_t:
		new_arr: types.object_array_t
		new_arr.count = v.count
		new_arr.value = make([dynamic]^types.object_t, len(v.value))
		for item, i in v.value {
			new_arr.value[i] = deep_clone_object(item)
		}
		copied.data = new_arr

	case string:
		copied.data = strings.clone(v)
	}

	return copied
}

prompt_user :: proc(token: ^types.token_t, stck: ^types.vm_t) {
	if token.type == .END_OF_FILE || token.type == .TERMINATOR {
		return
	}

	if g_snapshots == nil {
		g_snapshots = new(types.debug_snapshot_collection_t)
	}

	snap := new(types.debug_snapshot_t)
	snap.syntax = token

	curr_stack, _ := vm.current_frame(stck)
	for i := 0; i < curr_stack.count; i += 1 {
		original_obj := curr_stack.data[i]
		copied_obj := deep_clone_object(original_obj)
		append(&snap.stack, copied_obj)
	}

	for i := 0; i < len(g_output_log); i += 1 {
		copied_str := new_clone(g_output_log[i])
		append(&snap.output, copied_str)
	}

	append(&g_snapshots.snapshots, snap)
}

inspect_snapshots :: proc() {
	if g_snapshots == nil || len(g_snapshots.snapshots) == 0 {
		fmt.println("No snapshots gathered.")
		return
	}

	raw_fd := posix.FD(posix.STDIN_FILENO)

	orig_termios: posix.termios
	has_termios := posix.tcgetattr(raw_fd, &orig_termios) == .OK

	if has_termios {
		raw := orig_termios
		raw.c_lflag -= {.ICANON, .ECHO}
		raw.c_cc[.VMIN] = 1
		raw.c_cc[.VTIME] = 0

		posix.tcsetattr(raw_fd, .TCSANOW, &raw)
		defer posix.tcsetattr(raw_fd, .TCSANOW, &orig_termios)
	}

	selected_idx := 0
	scroll_offset := 0

	for {
		term_cols, term_rows := get_terminal_size(raw_fd)

		show_full_header := term_rows >= 10
		overhead := show_full_header ? 7 : 5

		visible_rows := term_rows - overhead
		if visible_rows < 1 do visible_rows = 1

		if selected_idx < scroll_offset {
			scroll_offset = selected_idx
		} else if selected_idx >= scroll_offset + visible_rows {
			scroll_offset = selected_idx - visible_rows + 1
		}

		fmt.print("\e[2J\e[H\e[?25l")

		total_content_w := term_cols - 10
		if total_content_w < 60 do total_content_w = 60

		left_w := max(16, total_content_w * 22 / 100)
		mid_w := max(22, total_content_w * 38 / 100)
		right_w := total_content_w - left_w - mid_w
		if right_w < 26 do right_w = 26

		if show_full_header {
			print_header(left_w, mid_w, right_w)
		} else {
			left_bar := strings.repeat("─", left_w)
			mid_bar := strings.repeat("─", mid_w)
			right_bar := strings.repeat("─", right_w)
			defer delete(left_bar)
			defer delete(mid_bar)
			defer delete(right_bar)
			fmt.printfln(
				" %s╭%s┬%s┬%s╮%s",
				CLR_BORDER,
				left_bar,
				mid_bar,
				right_bar,
				CLR_RESET,
			)
		}

		print_3way_split_view(selected_idx, scroll_offset, visible_rows, left_w, mid_w, right_w)
		print_footer(term_cols)

		buf: [1]byte
		n, _ := os.read(os.stdin, buf[:])

		if n <= 0 do break

		ch := buf[0]

		if ch == 'q' || ch == 'Q' {
			break
		} else if ch == 'k' || ch == 'K' {
			if selected_idx > 0 do selected_idx -= 1
		} else if ch == 'j' || ch == 'J' {
			if selected_idx < len(g_snapshots.snapshots) - 1 do selected_idx += 1
		} else if ch == 27 {
			if has_termios {
				raw := orig_termios
				raw.c_lflag -= {.ICANON, .ECHO}
				raw.c_cc[.VMIN] = 0
				raw.c_cc[.VTIME] = 1
				posix.tcsetattr(raw_fd, .TCSANOW, &raw)

				seq: [2]byte
				n_seq, _ := os.read(os.stdin, seq[:])

				raw.c_cc[.VMIN] = 1
				raw.c_cc[.VTIME] = 0
				posix.tcsetattr(raw_fd, .TCSANOW, &raw)

				if n_seq == 0 {
					break
				} else if n_seq >= 1 && seq[0] == '[' {
					if n_seq == 1 {
						os.read(os.stdin, seq[1:2])
					}
					if seq[1] == 'A' {
						if selected_idx > 0 do selected_idx -= 1
					} else if seq[1] == 'B' {
						if selected_idx < len(g_snapshots.snapshots) - 1 do selected_idx += 1
					}
				}
			} else {
				break
			}
		}
	}

	fmt.print("\e[?25h\n")
}

print_header :: proc(left_w, mid_w, right_w: int) {
	inner_w := left_w + mid_w + right_w + 2
	top_line := strings.repeat("─", inner_w)
	defer delete(top_line)

	fmt.printfln(" %s╭%s╮%s", CLR_BORDER, top_line, CLR_RESET)

	title := "🍒 CherryScript Debug Inspector"
	dev := "dev: kr4nkenwagen"

	avail := inner_w - 2
	if avail < 0 do avail = 0

	title_str := title
	dev_str := dev

	if len(title_str) + len(dev_str) + 1 > avail {
		if len(title_str) < avail {
			dev_str = dev_str[:max(0, avail - len(title_str) - 1)]
		} else {
			title_str = title_str[:avail]
			dev_str = ""
		}
	}

	gap_len := avail - len(title_str) - len(dev_str)
	if gap_len < 0 do gap_len = 0
	spaces := strings.repeat(" ", gap_len)
	defer delete(spaces)

	fmt.printfln(
		" %s│%s %s%s%s%s%s%s%s %s  │%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_TITLE,
		title_str,
		CLR_RESET,
		spaces,
		CLR_MUTED,
		dev_str,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)

	left_bar := strings.repeat("─", left_w)
	mid_bar := strings.repeat("─", mid_w)
	right_bar := strings.repeat("─", right_w)
	defer delete(left_bar)
	defer delete(mid_bar)
	defer delete(right_bar)

	fmt.printfln(" %s├%s┬%s┬%s┤%s", CLR_BORDER, left_bar, mid_bar, right_bar, CLR_RESET)
}

print_3way_split_view :: proc(
	selected_idx, scroll_offset, visible_rows, left_w, mid_w, right_w: int,
) {
	snap := g_snapshots.snapshots[selected_idx]

	// Header row
	left_hdr_plain := pad_right("TOKENS / TIMELINE", left_w - 2)
	mid_hdr_plain := pad_right("SOURCE CODE", mid_w - 2)
	right_hdr_plain := pad_right(
		fmt.tprintf("SNAPSHOT [%02d/%02d]", selected_idx + 1, len(g_snapshots.snapshots)),
		right_w - 2,
	)

	fmt.printfln(
		" %s│%s %s%s%s %s│%s %s%s%s %s│%s %s%s%s %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		left_hdr_plain,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		mid_hdr_plain,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		right_hdr_plain,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)

	left_bar := strings.repeat("─", left_w)
	mid_bar := strings.repeat("─", mid_w)
	right_bar := strings.repeat("─", right_w)
	defer delete(left_bar)
	defer delete(mid_bar)
	defer delete(right_bar)

	fmt.printfln(" %s├%s┼%s┼%s┤%s", CLR_BORDER, left_bar, mid_bar, right_bar, CLR_RESET)

	source_lines: []string
	if g_source_code != nil && len(g_source_code.content) > 0 {
		source_lines = strings.split_lines(g_source_code.content, context.temp_allocator)
	}

	target_code_line := snap.syntax != nil ? snap.syntax.line : 0

	code_scroll_offset := 0
	if target_code_line > 0 {
		code_scroll_offset = max(0, (target_code_line - 1) - visible_rows / 2)
	}

	stack_count := len(snap.stack)
	log_capacity := visible_rows - stack_count - 1
	if log_capacity < 0 do log_capacity = 0

	log_start_idx := 0
	if len(snap.output) > log_capacity {
		log_start_idx = len(snap.output) - log_capacity
	}

	for i := 0; i < visible_rows; i += 1 {
		// --- PANEL 1: TOKENS / TIMELINE ---
		left_formatted := ""
		left_idx := scroll_offset + i

		if left_idx < len(g_snapshots.snapshots) {
			s := g_snapshots.snapshots[left_idx]
			tok_label := pad_right(
				fmt.tprintf("%02d. %s (%v)", left_idx + 1, s.syntax.literal, s.syntax.type),
				left_w - 4,
			)

			if left_idx == selected_idx {
				left_formatted = fmt.tprintf("%s➔ %s%s", CLR_AMBER, tok_label, CLR_RESET)
			} else {
				left_formatted = fmt.tprintf("  %s", tok_label)
			}
		} else {
			left_formatted = pad_right("", left_w - 2)
		}

		// --- PANEL 2: SOURCE CODE WITH TOKEN HIGHLIGHTING ---
		mid_formatted := ""
		line_idx := code_scroll_offset + i

		if line_idx >= 0 && line_idx < len(source_lines) {
			line_num := line_idx + 1
			raw_line := source_lines[line_idx]

			is_active := (line_num == target_code_line)
			line_prefix := is_active ? ">" : " "

			prefix_vis_len := 8
			max_raw_len := max(0, (mid_w - 2) - prefix_vis_len)

			truncated_line := raw_line
			if len(truncated_line) > max_raw_len {
				truncated_line = truncated_line[:max_raw_len]
			}

			vis_len := prefix_vis_len + len(truncated_line)
			pad_len := max(0, (mid_w - 2) - vis_len)
			padding := strings.repeat(" ", pad_len)
			defer delete(padding)

			if is_active {
				tok_lit := (snap.syntax != nil) ? snap.syntax.literal : ""
				tok_idx := (len(tok_lit) > 0) ? strings.index(truncated_line, tok_lit) : -1

				line_body := ""
				if tok_idx != -1 {
					before := truncated_line[:tok_idx]
					tok := truncated_line[tok_idx:tok_idx + len(tok_lit)]
					after := truncated_line[tok_idx + len(tok_lit):]

					line_body = fmt.tprintf(
						"%s%s%s%s%s%s",
						before,
						CLR_TOKEN_HL,
						tok,
						CLR_RESET,
						CLR_AMBER,
						after,
					)
				} else {
					line_body = truncated_line
				}

				mid_formatted = fmt.tprintf(
					"%s%s %3d │ %s%s%s",
					CLR_AMBER,
					line_prefix,
					line_num,
					line_body,
					padding,
					CLR_RESET,
				)
			} else {
				mid_formatted = fmt.tprintf(
					"%s%s %3d │ %s%s%s",
					CLR_TEXT,
					line_prefix,
					line_num,
					truncated_line,
					padding,
					CLR_RESET,
				)
			}
		} else if len(source_lines) == 0 && i == 0 {
			mid_formatted = pad_right("  (no source loaded)", mid_w - 2)
		} else {
			mid_formatted = pad_right("", mid_w - 2)
		}

		// --- PANEL 3: STACK & LOGS ---
		right_formatted := ""
		right_idx := i

		if right_idx < stack_count {
			item := snap.stack[right_idx]

			type_badge := get_type_badge(item.type)
			const_flag := item.is_const ? "C " : "  "

			name_str := pad_right(fmt.tprintf("%v", item.name), 8)
			data_val_str := format_object_t(item^, 0)

			if len(data_val_str) > 0 {
				data_w := max(0, (right_w - 2) - 23)
				data_str := pad_right(data_val_str, data_w)

				right_formatted = fmt.tprintf(
					"%s[%02d]%s %s%s%s %s%s%s%s%s = %s%s%s",
					CLR_MUTED,
					right_idx,
					CLR_RESET,
					CLR_TYPE,
					type_badge,
					CLR_RESET,
					CLR_CONST,
					const_flag,
					CLR_CYAN,
					name_str,
					CLR_RESET,
					CLR_GREEN,
					data_str,
					CLR_RESET,
				)
			} else {
				// Hide '=' when there is no value to display (e.g. FUNCTION)
				blank_pad := pad_right("", max(0, (right_w - 2) - 20))
				right_formatted = fmt.tprintf(
					"%s[%02d]%s %s%s%s %s%s%s%s%s%s",
					CLR_MUTED,
					right_idx,
					CLR_RESET,
					CLR_TYPE,
					type_badge,
					CLR_RESET,
					CLR_CONST,
					const_flag,
					CLR_CYAN,
					name_str,
					CLR_RESET,
					blank_pad,
				)
			}
		} else if right_idx == stack_count && len(snap.output) > 0 {
			header_str := pad_right("--- LOG OUTPUT ---", right_w - 2)
			right_formatted = fmt.tprintf("%s%s%s", CLR_MUTED, header_str, CLR_RESET)
		} else {
			log_line_offset := right_idx - stack_count - 1
			log_idx := log_start_idx + log_line_offset

			if log_idx >= 0 && log_idx < len(snap.output) {
				log_text := pad_right(fmt.tprintf("%v", snap.output[log_idx]^), right_w - 7)
				right_formatted = fmt.tprintf("%sout>%s %s", CLR_MUTED, CLR_RESET, log_text)
			} else {
				right_formatted = pad_right("", right_w - 2)
			}
		}

		fmt.printfln(
			" %s│%s %s %s│%s %s %s│%s %s %s│%s",
			CLR_BORDER,
			CLR_RESET,
			left_formatted,
			CLR_BORDER,
			CLR_RESET,
			mid_formatted,
			CLR_BORDER,
			CLR_RESET,
			right_formatted,
			CLR_BORDER,
			CLR_RESET,
		)
	}

	fmt.printfln(" %s╰%s┴%s┴%s╯%s", CLR_BORDER, left_bar, mid_bar, right_bar, CLR_RESET)
}

print_footer :: proc(term_cols: int) {
	nav_str := fmt.tprintf(
		" %s❯%s Nav: %s[J/K]%s or %s[UP/DOWN]%s | Quit: %s[Q]%s or %s[ESC]%s",
		CLR_CYAN,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
	)
	fmt.println(nav_str)
}
