package main

import "core:fmt"
import "debug"
import "evaluator"
import "parser"
import "scan"
import "source_code"
import "stack"
import "sys"
import "token_list"
import "types"
import "vm"

main :: proc() {
	src, src_err := source_code.from_file("test2.jonx")
	if sys.is_error(src_err) {
		fmt.printf("%s\n", src_err)
	}
	tokens, tokens_err := scan.run(src)
	if sys.is_error(tokens_err) {
		sys.print_error(tokens_err, tokens)
	}
	synt, synt_err := parser.run(tokens, nil)
	if sys.is_error(synt_err) {
		sys.print_error(synt_err, tokens)
	}
	curr_vm, curr_vm_err := vm.create()
	if sys.is_error(curr_vm_err) {
		sys.print_error(curr_vm_err, tokens)
	}
	curr_stack, curr_stack_err := stack.create()
	if sys.is_error(curr_stack_err) {
		sys.print_error(curr_stack_err, tokens)
	}
	vm_err := vm.push_frame(curr_vm, curr_stack, false)
	if sys.is_error(vm_err) {
		sys.print_error(vm_err, tokens)
	}
	obj, obj_err := evaluator.run(synt, curr_vm, true)
	if sys.is_error(obj_err) {
		sys.print_error(obj_err, tokens)
	}
	if true {
		debug.inspect_snapshots()
	}
	source_code.remove(src)
	token_list.remove(tokens)
}

token_list_pretty_print :: proc(tokens: ^types.token_list_t) {
	for i := 0; i < tokens.length; i += 1 {
		fmt.printf("%s\n", tokens.list[i].type)
	}
}

syntax_pretty_print :: proc(syntax: ^types.syntax_t, indent: int) {
	if syntax == nil {
		return
	}
	for _ in 0 ..< indent {
		fmt.print("  ")
	}
	if syntax.token != nil {
		if syntax.token.literal != "" {
			fmt.printf("%s: '%s'\n", syntax.token.type, syntax.token.literal)
		} else {
			fmt.printf("%s\n", syntax.token.type)
		}
	} else {
		fmt.println("UNKNOWN syntax")
	}
	if syntax.left != nil || syntax.right != nil {
		syntax_pretty_print(syntax.left, indent + 1)
		syntax_pretty_print(syntax.right, indent + 1)
	}
}
