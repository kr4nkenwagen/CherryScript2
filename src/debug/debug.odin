package debug

import "../types"
import "../vm"
import "core:fmt"
import "core:os"

g_output_log: [dynamic]string

CLR_RESET :: "\e[0m"
CLR_BOLD :: "\e[1m"

CLR_BORDER :: "\e[38;5;238m" // Dark gray border
CLR_TITLE :: "\e[38;5;204m" // Cherry Pink
CLR_CYAN :: "\e[38;5;75m" // Muted Cyan
CLR_AMBER :: "\e[38;5;215m" // Soft Amber
CLR_GREEN :: "\e[38;5;114m" // Pastel Green
CLR_TEXT :: "\e[38;5;252m" // Crisp Off-White
CLR_MUTED :: "\e[38;5;243m" // Subdued Gray
CLR_ACCENT :: "\e[48;5;236m\e[38;5;220m" // Highlight badge

prompt_user :: proc(token: ^types.token_t, vmem: ^types.vm_t) {
	if token.type == .END_OF_FILE || token.type == .TERMINATOR {
		return
	}

	fmt.print("\e[2J\e[H") // Clear screen & home cursor

	print_header()

	// Next Instruction Bar
	// Format the raw token text to fixed length 32
	tok_info := fmt.tprintf("%s (%v)", token.literal, token.type)
	fmt.printfln(
		" %s│%s  %sNEXT INSTRUCTION%s   %s%-30s%s         %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
		CLR_ACCENT,
		tok_info,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)
	fmt.printfln(
		" %s├────────────────────────────────────────────────────────────┤%s",
		CLR_BORDER,
		CLR_RESET,
	)

	print_stack(vmem)
	print_output_log()

	// Prompt footer
	fmt.printfln(
		"\n %s❯%s Press %s[ENTER]%s to step instruction...",
		CLR_CYAN,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
	)

	buf: [1]byte
	os.read(os.stdin, buf[:])
}

print_header :: proc() {
	fmt.printfln(
		" %s╭────────────────────────────────────────────────────────────╮%s",
		CLR_BORDER,
		CLR_RESET,
	)
	fmt.printfln(
		" %s│%s 🍒 %sCherryScript%s Debugger %s│%s dev: %s%skr4nkenwagen%s               %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_TITLE,
		CLR_RESET,
		CLR_MUTED,
		CLR_RESET,
		CLR_BOLD,
		CLR_TEXT,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)
	fmt.printfln(
		" %s├────────────────────────────────────────────────────────────┤%s",
		CLR_BORDER,
		CLR_RESET,
	)
}

print_stack :: proc(vmem: ^types.vm_t) {
	curr_stack, _ := vm.current_frame(vmem)

	fmt.printfln(
		" %s│%s  %sSTACK FRAME%s %s(%-2d items)%s                                    %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
		CLR_MUTED,
		curr_stack.count,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)

	if curr_stack.count == 0 {
		fmt.printfln(
			" %s│%s    %s<empty stack>%s                                           %s│%s",
			CLR_BORDER,
			CLR_RESET,
			CLR_MUTED,
			CLR_RESET,
			CLR_BORDER,
			CLR_RESET,
		)
	}

	for i := 0; i < curr_stack.count; i += 1 {
		item := curr_stack.data[i]
		is_top := (i == curr_stack.count - 1)

		// Top marker formatted to exact width
		marker := is_top ? fmt.tprintf("%s top ➔%s ", CLR_AMBER, CLR_RESET) : "       "

		// Format value data to fixed string length 18
		val_str := fmt.tprintf("%v", item.data)

		fmt.printfln(
			" %s│%s %s%s[%02d]%s %s%-10s%s %s%-8s%s = %s%-18s%s       %s│%s",
			CLR_BORDER,
			CLR_RESET,
			marker,
			CLR_MUTED,
			i,
			CLR_RESET,
			CLR_CYAN,
			item.name,
			CLR_RESET,
			CLR_MUTED,
			item.type,
			CLR_RESET,
			CLR_GREEN,
			val_str,
			CLR_RESET,
			CLR_BORDER,
			CLR_RESET,
		)
	}
}

print_output_log :: proc() {
	fmt.printfln(
		" %s├────────────────────────────────────────────────────────────┤%s",
		CLR_BORDER,
		CLR_RESET,
	)
	fmt.printfln(
		" %s│%s  %sOUTPUT LOG%s                                                %s│%s",
		CLR_BORDER,
		CLR_RESET,
		CLR_BOLD,
		CLR_RESET,
		CLR_BORDER,
		CLR_RESET,
	)

	if len(g_output_log) == 0 {
		fmt.printfln(
			" %s│%s    %s<no output>%s                                             %s│%s",
			CLR_BORDER,
			CLR_RESET,
			CLR_MUTED,
			CLR_RESET,
			CLR_BORDER,
			CLR_RESET,
		)
	}

	for entry, i in g_output_log {
		fmt.printfln(
			" %s│%s    %s[%02d]%s %s%-45s%s      %s│%s",
			CLR_BORDER,
			CLR_RESET,
			CLR_MUTED,
			i,
			CLR_RESET,
			CLR_TEXT,
			entry,
			CLR_RESET,
			CLR_BORDER,
			CLR_RESET,
		)
	}
	fmt.printfln(
		" %s╰────────────────────────────────────────────────────────────╯%s",
		CLR_BORDER,
		CLR_RESET,
	)
}
