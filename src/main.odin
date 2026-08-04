package main

import "core:fmt"
import "core:os"
import "core:strconv"
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

debug_type :: enum {
	NONE,
	TOKENS,
	AST,
	EVAL,
}

g_debug: debug_type = .NONE
g_source_file := ""

parse_args :: proc() -> bool {
	i := 1
	for i < len(os.args) {
		val := os.args[i]
		if val == "debug" || val == "-debug" {
			if i + 1 < len(os.args) {
				parsed_val, ok := strconv.parse_int(os.args[i + 1])
				if ok && parsed_val >= 0 && parsed_val <= 3 {
					g_debug = debug_type(parsed_val)
					i += 1
				} else {
					fmt.printf("Error: '%s' is not a valid debug level (0-2)\n", os.args[i + 1])
					return false
				}
			}
		} else if os.exists(val) {
			g_source_file = val
		} else {
			fmt.printf("Invalid flag or file not found: %s\n", val)
			return false
		}
		i += 1
	}
	return true
}

step_1 :: proc() -> ^types.token_list_t {
	src, src_err := source_code.from_file(g_source_file)
	if sys.is_error(src_err) {
		fmt.printf("%s\n", src_err)
		return nil
	}
	tokens, tokens_err := scan.run(src)
	if sys.is_error(tokens_err) {
		sys.print_error(tokens_err, tokens)
		return nil
	}
	if g_debug == .TOKENS {
		debug.print_token_list(tokens)
		token_list.remove(tokens)
		return nil
	}
	return tokens
}

step_2 :: proc(tokens: ^types.token_list_t) -> ^types.program_t {
	if tokens == nil {
		return nil
	}
	synt, synt_err := parser.run(tokens, nil)
	if sys.is_error(synt_err) {
		sys.print_error(synt_err, tokens)
		return nil
	}
	if g_debug == .AST {
		debug.print_ast(synt)
		return nil
	}
	return synt
}

step_3 :: proc(program: ^types.program_t, tokens: ^types.token_list_t) {
	if program == nil || tokens == nil {
		return
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
	obj, obj_err := evaluator.run(program, curr_vm, g_debug == .EVAL)
	if sys.is_error(obj_err) {
		sys.print_error(obj_err, tokens)
	}
	if g_debug == .EVAL {
		debug.inspect_snapshots()
	}
}

main :: proc() {
	if !parse_args() {
		return
	}
	tokens := step_1()
	program := step_2(tokens)
	step_3(program, tokens)
	token_list.remove(tokens)
}
