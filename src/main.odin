package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "debug"
import "evaluator"
import "parser"
import "scanner"
import "source_code"
import "stack"
import "sys"
import "token_list"
import "types"
import "vendor:curl"
import "vm"

SOURCE_FILE_SUFFIX :: ".cherry"

parse_args :: proc() -> ^types.arguments_t {
	args := new(types.arguments_t)
	i := 1
	for i < len(os.args) {
		val := os.args[i]
		if val == "debug" || val == "-debug" {
			if i + 1 < len(os.args) {
				parsed_val, ok := strconv.parse_int(os.args[i + 1])
				if ok && parsed_val >= 0 && parsed_val <= 3 {
					args.debug_level = types.debug_type_t(parsed_val)
					i += 1
				} else {
					fmt.printf("Error: '%s' is not a valid debug level (0-2)\n", os.args[i + 1])
					return nil
				}
			}
		} else if os.exists(val) && strings.has_suffix(val, SOURCE_FILE_SUFFIX) do append(&args.source_files, val)
		i += 1
	}
	return args
}

step_0 :: proc(
	path: string,
	args: ^types.arguments_t,
) -> (
	src: ^types.source_code_t,
	code: types.exit_codes,
) {
	src = source_code.from_file(path) or_return
	return
}

step_1 :: proc(src: ^types.source_code_t, args: ^types.arguments_t) -> ^types.token_list_t {
	tokens, tokens_err := scanner.run(src)
	if sys.is_error(tokens_err) {
		token := tokens.list[len(tokens.list) - 1]
		sys.print_error(tokens_err, token, src)
		return nil
	}
	if args.debug_level == .TOKENS {
		debug.print_token_list(tokens)
		token_list.remove(tokens)
		return nil
	}
	if args.debug_level == .EVAL {
		debug.g_source_code = new(types.source_code_t)
		debug.g_source_code^ = src^
	}
	return tokens
}

step_2 :: proc(
	tokens: ^types.token_list_t,
	src: ^types.source_code_t,
	args: ^types.arguments_t,
) -> ^types.program_t {
	if tokens == nil do return nil
	synt, synt_err := parser.run(tokens, nil)
	if sys.is_error(synt_err) {
		token, _ := token_list.peek(tokens, 0)
		sys.print_error(synt_err, token, src)
		return nil
	}
	if args.debug_level == .AST {
		debug.print_ast(synt)
		return nil
	}
	return synt
}

step_3 :: proc(
	program: ^types.program_t,
	tokens: ^types.token_list_t,
	src: ^types.source_code_t,
	args: ^types.arguments_t,
) {
	if program == nil || tokens == nil do return
	curr_vm, curr_vm_err := vm.create()
	if sys.is_error(curr_vm_err) {
		sys.print_error(curr_vm_err, nil, src)
	}
	curl.global_init(curl.GLOBAL_DEFAULT)
	curr_stack, curr_stack_err := stack.create()

	if sys.is_error(curr_stack_err) do sys.print_error(curr_stack_err, nil, src)
	vm_err := vm.push_frame(curr_vm, curr_stack, false)
	if sys.is_error(vm_err) do sys.print_error(vm_err, nil, src)
	obj, obj_err := evaluator.run(program, curr_vm, args.debug_level == .EVAL)
	if sys.is_error(obj_err) do sys.print_error(obj_err, evaluator.g_current_syntax.token, src)
	if args.debug_level == .EVAL do debug.inspect_snapshots()
}

main :: proc() {
	args := parse_args()
	if args == nil do return
	for file in args.source_files {
		src, _ := step_0(file, args)
		tokens := step_1(src, args)
		program := step_2(tokens, src, args)
		step_3(program, tokens, src, args)
		token_list.remove(tokens)
	}
}
