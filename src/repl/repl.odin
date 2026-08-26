package repl

import "../evaluator"
import "../parser"
import "../scanner"
import "../source_code"
import "../stack"
import "../types"
import "../vm"
import "core:bufio"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor:curl"

run :: proc() -> (code: types.exit_codes) {
	reader: bufio.Reader
	bufio.reader_init(&reader, os.to_stream(os.stdin))
	defer bufio.reader_destroy(&reader)
	stck := vm.create() or_return
	curr_stck := stack.create() or_return
	curl.global_init(curl.GLOBAL_DEFAULT)
	vm.push_frame(stck, curr_stck, false) or_return
	for {
		fmt.print("> ")
		line, err := bufio.reader_read_string(&reader, '\n', context.temp_allocator)
		if err != nil {
			break
		}
		input := strings.trim_space(line)
		if input == "exit" || input == "quit" {
			break
		}

		if len(input) == 0 {
			continue
		}

		src := source_code.from_repl(line) or_return
		tokens := scanner.run(src) or_return
		prgm := parser.run(tokens, nil) or_return

		evaluator.run(prgm, stck, false)
		free_all(context.temp_allocator)
	}
	return
}
