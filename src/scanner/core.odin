package scanner

import "core:os"
import "core:fmt"
import "core:strings"

source_code :: struct {
  content : string,
  length : int,
  is_at_end : bool,
  pointer : int,
  line : int,
  column : int,
}

from_file :: proc(file: string) {
  data, err:= os.read_entire_file(file, context.allocator)
  if err != nil {
    return
  }
  defer delete(data)
  file_content := string(data)
  for c, i in file_content {
    fmt.printf("%c\n", c)
  }
}
