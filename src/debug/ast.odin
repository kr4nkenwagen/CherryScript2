package debug

import "../types"
import "core:fmt"

// ANSI Color Codes
ANSI_RESET :: "\x1b[0m"
ANSI_GRAY :: "\x1b[90m"
ANSI_CYAN :: "\x1b[36m"
ANSI_GREEN :: "\x1b[32m"
ANSI_YELLOW :: "\x1b[33m"
ANSI_MAGENTA :: "\x1b[35m"
ANSI_RED :: "\x1b[31m"

// Overload print_ast so it can take either a program_t (root) or a syntax_t (node)
print_ast :: proc {
	print_program,
	print_syntax,
}

// Entry point for a program block (handles the root and arrays of statements)
print_program :: proc(
	prog: ^types.program_t,
	prefix: string = "",
	is_last: bool = true,
	name: string = "",
) {
	if prog == nil do return

	// We only draw the tree markers if this is a sub-program (has an edge name, like "branch:")
	// If name is empty, we assume it's the root program and skip the trunk marker.
	is_root := name == ""

	if !is_root {
		marker := is_last ? "└── " : "├── "
		fmt.printf("%s%s%s%s", ANSI_GRAY, prefix, marker, ANSI_RESET)
		fmt.printf("%s%s:%s ", ANSI_CYAN, name, ANSI_RESET)
	}

	fmt.printf("%s[Program block: %v]%s\n", ANSI_MAGENTA, prog.type, ANSI_RESET)

	// Calculate prefix for the statements inside this program
	child_prefix := prefix
	if !is_root {
		child_prefix = fmt.tprintf("%s%s", prefix, is_last ? "    " : "│   ")
	}

	// Iterate through all statements, correctly identifying the last one
	for stmt, i in prog.statements {
		is_stmt_last := i == len(prog.statements) - 1
		print_syntax(stmt, child_prefix, is_stmt_last, "")
	}
}

// Handler for individual syntax nodes
print_syntax :: proc(
	node: ^types.syntax_t,
	prefix: string = "",
	is_last: bool = true,
	name: string = "",
) {
	if node == nil do return

	// 1. Draw the branch lines for the current node
	marker := is_last ? "└── " : "├── "
	fmt.printf("%s%s%s%s", ANSI_GRAY, prefix, marker, ANSI_RESET)

	// 2. Print the edge name (e.g., "left:", "right:") if provided
	if name != "" {
		fmt.printf("%s%s:%s ", ANSI_CYAN, name, ANSI_RESET)
	}

	// 3. Print the token data including line and column numbers
	if node.token != nil {
		fmt.printf(
			"%s[%v]%s %s'%s'%s %s(line: %d, col: %d)%s\n",
			ANSI_GREEN,
			node.token.type,
			ANSI_RESET,
			ANSI_YELLOW,
			node.token.literal,
			ANSI_RESET,
			ANSI_GRAY,
			node.token.line,
			node.token.column,
			ANSI_RESET,
		)
	} else {
		fmt.printf("%s[Empty Node]%s\n", ANSI_RED, ANSI_RESET)
	}

	// 4. Calculate the visual prefix for the next level down
	child_prefix := fmt.tprintf("%s%s", prefix, is_last ? "    " : "│   ")

	// 5. Count non-nil children to correctly calculate which one is the "last" one
	valid_children := 0
	if node.left != nil do valid_children += 1
	if node.right != nil do valid_children += 1
	if node.value != nil do valid_children += 1
	if node.branch != nil do valid_children += 1
	if node.args != nil do valid_children += 1

	current_child := 0

	// Helper to print syntax_t children
	print_syntax_child :: proc(
		child: ^types.syntax_t,
		child_name: string,
		current: ^int,
		total: int,
		prefix: string,
	) {
		if child != nil {
			current^ += 1
			print_syntax(child, prefix, current^ == total, child_name)
		}
	}

	// Helper to print program_t children
	print_program_child :: proc(
		prog: ^types.program_t,
		prog_name: string,
		current: ^int,
		total: int,
		prefix: string,
	) {
		if prog != nil {
			current^ += 1
			// We now just bounce back to print_program!
			print_program(prog, prefix, current^ == total, prog_name)
		}
	}

	// Print all children in order
	print_syntax_child(node.left, "left", &current_child, valid_children, child_prefix)
	print_syntax_child(node.right, "right", &current_child, valid_children, child_prefix)
	print_syntax_child(node.value, "value", &current_child, valid_children, child_prefix)
	print_program_child(node.branch, "branch", &current_child, valid_children, child_prefix)
	print_program_child(node.args, "args", &current_child, valid_children, child_prefix)
}
