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

winsize :: struct {
	ws_row:    c.ushort,
	ws_col:    c.ushort,
	ws_xpixel: c.ushort,
	ws_ypixel: c.ushort,
}

// OS-specific ioctl request codes
when ODIN_OS == .Darwin {
	TIOCGWINSZ: c.ulong : 0x40087468
} else {
	TIOCGWINSZ: c.ulong : 0x5413 // Linux / macOS fallback
}

foreign import libc "system:c"

@(default_calling_convention = "c")
foreign libc {
	// Bind ioctl specifically for our winsize struct
	ioctl :: proc(fd: c.int, request: c.ulong, arg: ^winsize) -> c.int ---
}

// Fetch current terminal height
get_terminal_rows :: proc(raw_fd: posix.FD) -> int {
	ws: winsize
	// Call the C-bound ioctl function
	if ioctl(c.int(raw_fd), TIOCGWINSZ, &ws) != -1 {
		if ws.ws_row > 5 {
			return int(ws.ws_row)
		}
	}
	return 24 // Fallback if ioctl fails
}
// Called every instruction state to passively record execution history
prompt_user :: proc(token: ^types.token_t, vmem: ^types.vm_t) {
	if token.type == .END_OF_FILE || token.type == .TERMINATOR {
		return
	}

	if g_snapshots == nil {
		g_snapshots = new(types.debug_snapshot_collection_t)
	}

	snap := new(types.debug_snapshot_t)
	snap.syntax = token

	// Deep copy stack objects at this exact point in time
	curr_stack, _ := vm.current_frame(vmem)
	for i := 0; i < curr_stack.count; i += 1 {
		original_obj := curr_stack.data[i]

		// 1. Allocate a completely new object on the heap and copy the data over
		// (Assuming original_obj is a pointer. If it's a value type, remove the ^)
		copied_obj := new_clone(original_obj^)

		// 2. IMPORTANT: If your object contains strings (like item.name or item.data)
		// that the VM will explicitly free later, you MUST deep-copy those strings too:
		// copied_obj.name = strings.clone(original_obj.name)
		// copied_obj.data = strings.clone(original_obj.data.(string)) // if data is an 'any' or union containing a string

		append(&snap.stack, copied_obj)
	}

	// Deep copy pointers/strings from the current output log state.
	// Note: If snap.output stores pointers (^string), you should allocate clones of the strings
	// because `g_output_log` reallocating its backing array will invalidate old pointers.
	for i := 0; i < len(g_output_log); i += 1 {
		copied_str := new_clone(g_output_log[i])
		append(&snap.output, copied_str)
	}

	// Note: changed &snap^ to snap^ (assuming g_snapshots.snapshots stores values, not pointers. If it stores pointers, just use `snap`)
	append(&g_snapshots.snapshots, &snap^)
}


inspect_snapshots :: proc() {
	if g_snapshots == nil || len(g_snapshots.snapshots) == 0 {
		fmt.println("No snapshots gathered.")
		return
	}

	// Lock directly onto Standard Input, explicitly cast to posix.FD
	raw_fd := posix.FD(posix.STDIN_FILENO)

	// Configure Termios Raw Mode on STDIN
	orig_termios: posix.termios
	has_termios := posix.tcgetattr(raw_fd, &orig_termios) == .OK

	if has_termios {
		raw := orig_termios
		raw.c_lflag -= {.ICANON, .ECHO}
		raw.c_cc[.VMIN] = 1 // Block until at least 1 character is typed
		raw.c_cc[.VTIME] = 0 // No read timeout

		posix.tcsetattr(raw_fd, .TCSANOW, &raw)
		// Ensure terminal goes back to normal when we exit
		defer posix.tcsetattr(raw_fd, .TCSANOW, &orig_termios)
	}

	selected_idx := 0
	scroll_offset := 0

	for {
		// Detect dynamic terminal size
		term_rows := get_terminal_rows(raw_fd)

		// Calculate how many rows we can safely display for the list view
		// (Terminal Height) minus (Header, Dividers, Prompt, and Padding)
		visible_rows := term_rows - 10
		if visible_rows < 5 do visible_rows = 5

		// Update scrolling viewport if selected item moves out of bounds
		if selected_idx < scroll_offset {
			scroll_offset = selected_idx
		} else if selected_idx >= scroll_offset + visible_rows {
			scroll_offset = selected_idx - visible_rows + 1
		}

		// Clear screen (\e[2J), Home cursor (\e[H), Hide cursor (\e[?25l)
		fmt.print("\e[2J\e[H\e[?25l")

		print_header()
		print_split_view(selected_idx, scroll_offset, visible_rows)

		fmt.printfln(
			"\n %s❯%s Nav: %s[J/K]%s or %s[UP/DOWN]%s | Quit: %s[Q]%s or %s[ESC]%s",
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

		// Block and wait for keystroke on standard input
		buf: [1]byte
		n, _ := os.read(os.stdin, buf[:])

		if n <= 0 {
			break
		}

		ch := buf[0]

		if ch == 'q' || ch == 'Q' {
			break
		} else if ch == 'k' || ch == 'K' {
			if selected_idx > 0 do selected_idx -= 1
		} else if ch == 'j' || ch == 'J' {
			if selected_idx < len(g_snapshots.snapshots) - 1 do selected_idx += 1
		} else if ch == 27 { 	// ESC key or start of ANSI sequence
			if has_termios {
				// Temporarily set non-blocking read to check for arrow keys
				raw := orig_termios
				raw.c_lflag -= {.ICANON, .ECHO}
				raw.c_cc[.VMIN] = 0
				raw.c_cc[.VTIME] = 1 // 100ms timeout
				posix.tcsetattr(raw_fd, .TCSANOW, &raw)

				seq: [2]byte
				n_seq, _ := os.read(os.stdin, seq[:])

				// Restore blocking read mode
				raw.c_cc[.VMIN] = 1
				raw.c_cc[.VTIME] = 0
				posix.tcsetattr(raw_fd, .TCSANOW, &raw)

				if n_seq == 0 {
					break
				} else if n_seq >= 1 && seq[0] == '[' {
					if n_seq == 1 {
						os.read(os.stdin, seq[1:2])
					}
					if seq[1] == 'A' { 	// UP Arrow
						if selected_idx > 0 do selected_idx -= 1
					} else if seq[1] == 'B' { 	// DOWN Arrow
						if selected_idx < len(g_snapshots.snapshots) - 1 do selected_idx += 1
					}
				}
			} else {
				break
			}
		}
	}

	// Restore cursor visibility before exiting
	fmt.print("\e[?25h\n")
}

print_header :: proc() {
	fmt.printfln(
		" %s╭────────────────────────────────────────────────────────────────────────────╮%s",
		CLR_BORDER,
		CLR_RESET,
	)
	// Inner width is exactly 76 visible characters
	fmt.printfln(
		" %s│%s 🍒 %sCherryScript%s Debug Inspector                          %sdev: %s%skr4nkenwagen%s %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_TITLE,
		CLR_RESET,
		CLR_MUTED,
		CLR_BOLD,
		CLR_TEXT,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)
	fmt.printfln(
		" %s├──────────────────────────────┬─────────────────────────────────────────────┤%s",
		CLR_BORDER,
		CLR_RESET,
	)
}

print_split_view :: proc(selected_idx: int, scroll_offset: int, visible_rows: int) {
	snap := g_snapshots.snapshots[selected_idx]

	// Header row: Left is 28 chars, Right is 43 chars
	right_hdr := fmt.tprintf(
		"INSPECTING SNAPSHOT [%02d/%02d]",
		selected_idx + 1,
		len(g_snapshots.snapshots),
	)

	fmt.printfln(
		" %s│%s %s%-28s%s %s│%s %s%-43s%s %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		"TOKENS / TIMELINE",
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		right_hdr,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)
	fmt.printfln(
		" %s├──────────────────────────────┼─────────────────────────────────────────────┤%s",
		CLR_BORDER,
		CLR_RESET,
	)

	// Render exactly `visible_rows` to lock into the terminal bounds
	for i := 0; i < visible_rows; i += 1 {
		// --- LEFT COLUMN: Scrolling Timeline (Target: exactly 28 chars) ---
		left_str := ""
		left_idx := scroll_offset + i

		if left_idx < len(g_snapshots.snapshots) {
			s := g_snapshots.snapshots[left_idx]
			tok_label := fmt.tprintf(
				"%02d. %s (%v)",
				left_idx + 1,
				s.syntax.literal,
				s.syntax.type,
			)

			// Hard-truncate to prevent layout breaks
			if len(tok_label) > 26 do tok_label = tok_label[:26]

			if left_idx == selected_idx {
				left_str = fmt.tprintf("%s➔ %-26s%s", CLR_AMBER, tok_label, CLR_RESET)
			} else {
				left_str = fmt.tprintf("  %-26s", tok_label)
			}
		} else {
			left_str = "                            " // 28 spaces
		}

		// --- RIGHT COLUMN: Static Stack & Logs (Target: exactly 43 chars) ---
		right_str := ""
		right_idx := i

		if right_idx < len(snap.stack) {
			item := snap.stack[right_idx]

			// Truncate name and data safely
			name_str := fmt.tprintf("%v", item.name)
			if len(name_str) > 8 do name_str = name_str[:8]

			data_str := fmt.tprintf("%v", item.data)
			if len(data_str) > 27 do data_str = data_str[:27]

			right_str = fmt.tprintf(
				"%s[%02d]%s %s%-8s%s = %s%-27s%s",
				CLR_MUTED,
				right_idx,
				CLR_RESET,
				CLR_CYAN,
				name_str,
				CLR_RESET,
				CLR_GREEN,
				data_str,
				CLR_RESET,
			)
		} else if right_idx == len(snap.stack) && len(snap.output) > 0 {
			right_str = fmt.tprintf("%s%-43s%s", CLR_MUTED, "--- LOG OUTPUT ---", CLR_RESET)
		} else {
			log_idx := right_idx - len(snap.stack) - 1
			if log_idx >= 0 && log_idx < len(snap.output) {
				log_text := fmt.tprintf("%v", snap.output[log_idx]^)
				if len(log_text) > 38 do log_text = log_text[:38]

				right_str = fmt.tprintf("%sout>%s %-38s", CLR_MUTED, CLR_RESET, log_text)
			} else {
				right_str = "                                           " // 43 spaces
			}
		}

		// Because we padded left_str to 28 chars and right_str to 43 chars exactly,
		// we use just `%s` here so the ANSI codes don't break the string width calculation!
		fmt.printfln(
			" %s│%s %s %s│%s %s %s│%s",
			CLR_BORDER,
			CLR_RESET,
			left_str,
			CLR_BORDER,
			CLR_RESET,
			right_str,
			CLR_BORDER,
			CLR_RESET,
		)
	}

	fmt.printfln(
		" %s╰──────────────────────────────┴─────────────────────────────────────────────╯%s",
		CLR_BORDER,
		CLR_RESET,
	)
}
