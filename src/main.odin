package main

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"
import "debug"
import "evaluator"
import "parser"
import "repl"
import "scanner"
import "source_code"
import "stack"
import "sys"
import "token"
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
		} else if os.exists(val) && strings.has_suffix(val, SOURCE_FILE_SUFFIX) {
			append(&args.source_files, val)
		} else {
			append(&args.pipe, val)
		}
		i += 1
	}
	return args
}

tokenize :: proc(
	path: string,
	args: ^types.arguments_t,
) -> (
	src: ^types.source_code_t,
	code: types.exit_codes,
) {
	src = source_code.from_file(path) or_return
	return
}

build_token_list :: proc(
	src: ^types.source_code_t,
	args: ^types.arguments_t,
) -> (
	tokens: ^types.token_list_t,
	code: types.exit_codes,
) {

	tokens, code = scanner.run(src)
	if sys.is_error(code) {
		tkn: ^types.token_t = nil
		if tokens != nil && len(tokens.list) > 0 {
			tkn = tokens.list[len(tokens.list) - 1]
		} else {
			tkn = token.generate_unknown_token() or_return
		}
		sys.print_error(code, tkn, src)
		return nil, code
	}
	if len(os.get_env_alloc("CHERRY_DUMP", context.temp_allocator)) > 0 {
		_ = os.write_entire_file_from_string("/tmp/opencode/combined_dump.cherry", src.content)
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

build_program :: proc(
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

interprete_program :: proc(
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
	_, code = evaluator.run(program, curr_vm)
	if sys.is_error(code) {
		err_token := program.stats.current_syntax != nil ? program.stats.current_syntax.token : nil
		sys.print_error(code, err_token, src)
		return code
	}
	if args.debug_level == .EVAL do debug.inspect_snapshots()
	return .OK
}

main :: proc() {
	args := parse_args()
	err_code := types.exit_codes.OK
	if len(args.source_files) == 0 && len(args.pipe) == 0 {
		err_code = repl.run(args)
		if err_code != .OK do os.exit(int(err_code))
	} else if len(args.pipe) != 0 {
		repl.pipe(strings.join(args.pipe[:], " "), args)
	}
	if args == nil do return
	for file in args.source_files {
		src, _ := tokenize(file, args)
		tokens, tokens_code := build_token_list(src, args)
		if tokens_code != .OK {
			err_code = tokens_code
			continue
		}
		program, parse_code := build_program(tokens, src, args)
		if parse_code != .OK {
			err_code = parse_code
			token_list.remove(tokens)
			continue
		}
		if program != nil do program.args = args
		eval_code := interprete_program(program, tokens, src, args)
		if eval_code != .OK do err_code = eval_code
		token_list.remove(tokens)
	}
	if err_code != .OK do os.exit(int(err_code))
}
