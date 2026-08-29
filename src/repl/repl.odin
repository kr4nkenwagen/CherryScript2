package repl

import "../evaluator"
import "../parser"
import "../scanner"
import "../source_code"
import "../stack"
import "../sys"
import "../token_list"
import "../types"
import "../vm"
import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor:curl"

pipe :: proc(input: string, args: ^types.arguments_t) -> (code: types.exit_codes) {
	src, src_err := source_code.from_repl(input)
	defer source_code.remove(src)
	if sys.is_error(src_err) {
		sys.print_error(src_err, nil, src)
	}
	tokens, tokens_err := scanner.run(src)
	defer token_list.remove(tokens)
	if sys.is_error(tokens_err) {
		last_token := len(tokens.list) > 0 ? tokens.list[len(tokens.list) - 1] : nil
		sys.print_error(tokens_err, last_token, src)
	}
	prgm, prgm_err := parser.run(tokens, nil)
	prgm.args = args
	if sys.is_error(prgm_err) {
		sys.print_error(prgm_err, tokens.list[tokens.pointer], src)
	}
	stck := vm.create() or_return
	curr_stck := stack.create() or_return
	curl.global_init(curl.GLOBAL_DEFAULT)
	vm.push_frame(stck, curr_stck, false) or_return
	obj, eval_err := evaluator.run(prgm, stck)
	if sys.is_error(eval_err) {
		err_token := prgm.stats.current_syntax != nil ? prgm.stats.current_syntax.token : nil
		sys.print_error(eval_err, err_token, src)
	}
	if obj != nil {
		evaluator.print_object(obj, prgm)
		fmt.printf("\n")
	}
	free_all(context.temp_allocator)
	return
}

run :: proc(args: ^types.arguments_t) -> (code: types.exit_codes) {
	is_tty := os.is_tty(os.stdin)
	reader: bufio.Reader
	editor: Editor
	if is_tty {
		editor.history = load_history()
		editor.hist_idx = len(editor.history)
	} else {
		bufio.reader_init(&reader, os.to_stream(os.stdin))
	}
	defer if is_tty {
		destroy_editor(&editor)
	} else {
		bufio.reader_destroy(&reader)
	}
	stck := vm.create() or_return
	curr_stck := stack.create() or_return
	curl.global_init(curl.GLOBAL_DEFAULT)
	vm.push_frame(stck, curr_stck, false) or_return
	for {
		line: string
		defer if is_tty {
			delete(line)
		}
		if is_tty {
			got, eof := read_line(&editor)
			if eof do break
			line = got
		} else {
			fmt.print("> ")
			got, err := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
			if err != nil {
				break
			}
			line = got
		}
		input := strings.trim_space(line)
		if input == "exit" || input == "quit" {
			break
		}
		if len(input) == 0 {
			continue
		}
		src, src_err := source_code.from_repl(line)
		if sys.is_error(src_err) {
			sys.print_error(src_err, nil, src)
			continue
		}
		tokens, tokens_err := scanner.run(src)
		if sys.is_error(tokens_err) {
			last_token := len(tokens.list) > 0 ? tokens.list[len(tokens.list) - 1] : nil
			sys.print_error(tokens_err, last_token, src)
			continue
		}
		prgm, prgm_err := parser.run(tokens, nil)
		prgm.args = args
		if sys.is_error(prgm_err) {
			sys.print_error(prgm_err, tokens.list[tokens.pointer], src)
			continue
		}
		obj, eval_err := evaluator.run(prgm, stck)
		if sys.is_error(eval_err) {
			err_token := prgm.stats.current_syntax != nil ? prgm.stats.current_syntax.token : nil
			sys.print_error(eval_err, err_token, src)
			continue
		}
		if obj != nil {
			evaluator.print_object(obj, prgm)
			fmt.printf("\n")
			prgm.stats.force_print_newline = true
		}
		if is_tty && !prgm.stats.force_print_newline {
			fmt.println()
		}
		free_all(context.temp_allocator)
	}
	return
}
