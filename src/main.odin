package main
import scan "scanner"
import "core:fmt"

main :: proc() {
  src := scan.from_file("test.jonx")
  fmt.printf("%s\n", src.content)
  for i in 0 ..< src.length {
    fmt.printf("[%i]%c ", src.pointer, scan.advance(src))
  }
  scan.source_code_delete(src)
  }
