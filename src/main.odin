package main
import "source_code"
import token "token"
import token_list "token_list"
import "core:fmt"

main :: proc() {
  src := source_code.from_file("test.jonx")
  fmt.printf("%s\n", src.content)
  for i in 0 ..< src.length {
    fmt.printf("[%i]%c ", src.pointer, source_code.advance(src))
  }
  source_code.source_code_delete(src)
  }
