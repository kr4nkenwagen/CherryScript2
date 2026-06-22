package main
import "core:fmt"
import scan "scan"
import "source_code"
import token_list "token_list"

main :: proc() {
	src := source_code.from_file("test.jonx")
	tokens, err := scan.run(src)
	for i := 0; i < tokens.length; i += 1 {
		fmt.printf("%i\n", tokens.list[i].type)
	}
	source_code.source_code_delete(src)
}
