package main
import "core:fmt"
import scan "scan"
import "source_code"
import token_list "token_list"

main :: proc() {
	src := source_code.from_file("test.jonx")
	tokens, err := scan.run(src)
	fmt.printf("%s\n", src.content)
	for i in 0 ..< src.length {
		fmt.printf("[%i]%c ", src.pointer, source_code.advance(src))
	}
	source_code.source_code_delete(src)
}
