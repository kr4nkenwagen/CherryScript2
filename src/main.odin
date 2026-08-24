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

step_1 :: proc(
	src: ^types.source_code_t,
	args: ^types.arguments_t,
) -> (
	tokens: ^types.token_list_t,
	code: types.exit_codes,
) {
	tokens, code = scanner.run(src)
	if sys.is_error(code) {
		token := tokens.list[len(tokens.list) - 1]
		sys.print_error(code, token, src)
		return nil, code
	}
	if args.debug_level == .TOKENS {
		debug.print_token_list(tokens)
		token_list.remove(tokens)
		return nil, .OK
	}
	if args.debug_level == .EVAL {
		debug.g_source_code = new(types.source_code_t)
		debug.g_source_code^ = src^
	}
	return tokens, .OK
}

step_2 :: proc(
	tokens: ^types.token_list_t,
	src: ^types.source_code_t,
	args: ^types.arguments_t,
) -> (
	program: ^types.program_t,
	code: types.exit_codes,
) {
	if tokens == nil do return nil, .OK
	program, code = parser.run(tokens, nil)
	if sys.is_error(code) {
		token, _ := token_list.peek(tokens, 0)
		sys.print_error(code, token, src)
		return nil, code
	}
	if args.debug_level == .AST {
		debug.print_ast(program)
		return nil, .OK
	}
	return program, .OK
}

step_3 :: proc(
	program: ^types.program_t,
	tokens: ^types.token_list_t,
	src: ^types.source_code_t,
	args: ^types.arguments_t,
) -> (
	code: types.exit_codes,
) {
	if program == nil || tokens == nil do return .OK
	curr_vm, vm_create_code := vm.create()
	if sys.is_error(vm_create_code) {
		sys.print_error(vm_create_code, nil, src)
		return vm_create_code
	}
	curl.global_init(curl.GLOBAL_DEFAULT)
	curr_stack, stack_code := stack.create()

	if sys.is_error(stack_code) do sys.print_error(stack_code, nil, src)
	vm_err := vm.push_frame(curr_vm, curr_stack, false)
	if sys.is_error(vm_err) do sys.print_error(vm_err, nil, src)
	_, code = evaluator.run(program, curr_vm, args.debug_level == .EVAL)
	if sys.is_error(code) {
		sys.print_error(code, evaluator.g_current_syntax.token, src)
		return code
	}
	if args.debug_level == .EVAL do debug.inspect_snapshots()
	return .OK
}

main :: proc() {
	args := parse_args()
	if args == nil do return
	err_code := types.exit_codes.OK
	for file in args.source_files {
		src, _ := step_0(file, args)
		tokens, tokens_code := step_1(src, args)
		if tokens_code != .OK {
			err_code = tokens_code
			continue
		}
		program, parse_code := step_2(tokens, src, args)
		if parse_code != .OK {
			err_code = parse_code
			token_list.remove(tokens)
			continue
		}
		eval_code := step_3(program, tokens, src, args)
		if eval_code != .OK do err_code = eval_code
		token_list.remove(tokens)
	}
	if err_code != .OK do os.exit(int(err_code))
}
