package debug

import "../types"
import "core:fmt"


print_token_list :: proc(list: ^types.token_list_t) {
	if list == nil {
		fmt.printf("%s[Error: Token list is nil]%s\n", ANSI_RED, ANSI_RESET)
		return
	}

	// Print Header
	fmt.printf(
		"\n%s=== Token List Dump (Tokens: %d, Pointer: %d) ===%s\n",
		ANSI_MAGENTA,
		list.length,
		list.pointer,
		ANSI_RESET,
	)

	fmt.printf(
		"%s%-5s │ %-10s │ %-8s │ %-18s │ %s%s\n",
		ANSI_GRAY,
		"INDEX",
		"LINE",
		"COLUMN",
		"TYPE",
		"LITERAL",
		ANSI_RESET,
	)
	fmt.printf(
		"%s──────┼────────────┼──────────┼────────────────────┼─────────────────%s\n",
		ANSI_GRAY,
		ANSI_RESET,
	)

	// We use list.length instead of len(list.list) to respect your struct's internal tracking
	for i := 0; i < list.length; i += 1 {
		tok := list.list[i]

		if tok == nil {
			fmt.printf("%s[%03d] │ %s<NIL TOKEN>%s\n", ANSI_GRAY, i, ANSI_RED, ANSI_RESET)
			continue
		}

		// Color-code the token types dynamically based on their category
		type_color := ANSI_GREEN
		#partial switch tok.type {
		case .END_OF_FILE:
			type_color = ANSI_MAGENTA
		case .ERROR, .UNKNOWN_TOKEN:
			type_color = ANSI_RED
		case .STRING_WRAPPER, .NUMBER:
			type_color = ANSI_YELLOW
		case .IDENTIFIER:
			type_color = ANSI_CYAN
		}

		// %q wraps the literal in quotes and safely escapes newlines (\n) or tabs (\t)
		fmt.printf(
			"%s[%03d] %s│ Line: %s%04d %s│ Col: %s%-3d %s│ %s%-18v %s│ %s%q%s\n",
			ANSI_GRAY,
			i,
			ANSI_GRAY,
			ANSI_CYAN,
			tok.line,
			ANSI_GRAY,
			ANSI_CYAN,
			tok.column,
			ANSI_GRAY,
			type_color,
			tok.type,
			ANSI_GRAY,
			ANSI_YELLOW,
			tok.literal,
			ANSI_RESET,
		)
	}
	fmt.printf(
		"%s════════════════════════════════════════════════════════════════════%s\n\n",
		ANSI_GRAY,
		ANSI_RESET,
	)
}
