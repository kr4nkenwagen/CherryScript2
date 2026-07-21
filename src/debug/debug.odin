package debug

import "../types"
import "../vm"
import "core:fmt"
import "core:os"

g_output_log: [dynamic]string

prompt_user :: proc(token: ^types.token_t, vmem: ^types.vm_t) {
	if token.type == .END_OF_FILE || token.type == .TERMINATOR {
		return
	}
	fmt.print("\e[2J\e[H")
	print_header()
	RESET :: "\e[0m"
	BOLD :: "\e[1m"
	GRAY :: "\e[90m"
	CYAN :: "\e[36m"
	MAGENTA :: "\e[35m"
	BRIGHT_YELLOW :: "\e[93m"
	fmt.printfln(
		"%s[%sEXEC%s] Next Instruction: %s%s%s%s %s(%v)%s",
		GRAY,
		MAGENTA,
		GRAY,
		BOLD,
		BRIGHT_YELLOW,
		token.literal,
		RESET,
		GRAY,
		token.type,
		RESET,
	)
	print_stack(vmem)
	print_output_log()
	fmt.printfln(
		"%s❯ Press %s[ENTER]%s %sto execute next instruction...%s",
		CYAN,
		BOLD,
		RESET,
		GRAY,
		RESET,
	)
	buf: [1]byte
	os.read(os.stdin, buf[:])
}

print_stack :: proc(vmem: ^types.vm_t) {
	curr_stack, _ := vm.current_frame(vmem)
	RESET :: "\e[0m"
	BOLD :: "\e[1m"
	GRAY :: "\e[90m"
	CYAN :: "\e[36m"
	YELLOW :: "\e[33m"
	GREEN :: "\e[32m"

	fmt.printfln(
		"\n%s─── STACK FRAME ───────────────────────────────────────────%s",
		BOLD,
		RESET,
	)
	for i := 0; i < curr_stack.count; i += 1 {
		item := curr_stack.data[i]
		is_top := (i == curr_stack.count - 1)
		marker := is_top ? "TOP ➔" : "     "
		fmt.printfln(
			" %s%s%s %s[%02d]%s %s%-16s%s %s%-12s%s %s%s%s",
			YELLOW,
			marker,
			RESET,
			GRAY,
			i,
			RESET,
			CYAN,
			item.name,
			RESET,
			GRAY,
			item.type,
			RESET,
			GREEN,
			item.data,
			RESET,
		)
	}

	fmt.printfln(
		"%s───────────────────────────────────────────────────────────%s\n",
		GRAY,
		RESET,
	)
}

print_output_log :: proc() {
	RESET :: "\e[0m"
	BOLD :: "\e[1m"
	GRAY :: "\e[90m"
	GREEN :: "\e[32m"
	fmt.printfln(
		"\n%s─── OUTPUT LOG ─────────────────────────────────────────────%s",
		BOLD,
		RESET,
	)
	for entry, i in g_output_log {
		fmt.printfln(" %s[%02d]%s %s%s%s", GRAY, i, RESET, GREEN, entry, RESET)
	}
	fmt.printfln(
		"%s───────────────────────────────────────────────────────────%s",
		GRAY,
		RESET,
	)
}

print_header :: proc() {
	RESET :: "\e[0m"
	BOLD :: "\e[1m"
	RED :: "\e[91m"
	GRAY :: "\e[90m"
	WHITE :: "\e[97m"

	// Minimalistic ASCII Art / Banner Header
	fmt.println(RED + BOLD + " 🍒 CherryScript " + WHITE + "Debugger" + RESET)
	fmt.println(GRAY + " Created by " + WHITE + BOLD + "kr4nkenwagen" + RESET)
	fmt.println(
		GRAY +
		" ───────────────────────────────────────────────────────────" +
		RESET,
	)
}
