package scan

import "../source_code"
import "../token"
import "../token_list"

consume_comment :: proc(src: ^source_code.source_code_t) -> bool {
  if src == nil || source_code.peek(src, 0) != '#' {
    return false
  }
  for !src.is_at_end {
    c:= rune(source_code.advance(src))
    if c == '\n' || c == '#' {
      return true
    }
  }
  return true
}

consume_string :: proc(src: ^source_code.source_code_t) -> (string, bool) {
  if src == nil || (source_code.peek(src, 0) != '\'' && source_code.peek(src, 0) != '"') {
    return "", false
  }
  exit_char:= rune(source_code.peek(src, 0)) == '"' ? '"' : '\''
  size:= int(1)
  for source_code.peek(src, size) != exit_char {
    size+=1
    if src.pointer + size >= src.length {
      //HERE WE NEED TO ERR 'err_eof_in_string'
      return "", false
    }
  }
  i:=0
  for i < size - 1 {
    source_code.advance(src)
  }
  return src.content[src.pointer : src.pointer + size], true
}

is_number :: proc(character: rune) -> bool {
  switch(character) {
  case '0': fallthrough
  case '1': fallthrough
  case '2': fallthrough
  case '3': fallthrough
  case '4': fallthrough
  case '5': fallthrough
  case '6': fallthrough
  case '7': fallthrough
  case '8': fallthrough
  case '9': return true
  }
  return false
}

is_end_of_word :: proc(character: rune) -> bool {
  switch (character) {
  case '\n': fallthrough
  case '\t': fallthrough
  case ' ': fallthrough
  case ';': fallthrough
  case '[': fallthrough
  case ']': fallthrough
  case '(': fallthrough
  case ')': fallthrough
  case '{': fallthrough
  case '}': fallthrough
  case ':': fallthrough
  case '=': fallthrough
  case '+': fallthrough
  case '-': fallthrough
  case '/': fallthrough
  case '*': fallthrough
  case '!': fallthrough
  case '<': fallthrough
  case '>': fallthrough
  case '.': fallthrough
  case ',':
    return true;
  }
  return false
}

consume_word :: proc(src: ^source_code.source_code_t) -> (string, bool) {
   if src == nil {
    return "", false
  }
  start_position:= src.pointer
  for !src.is_at_end {
    if is_end_of_word(source_code.advance(src)) {
      break
    }
  }
  total_length:= int(src.pointer - start_position + 1)
  result:= string(src.content[start_position : start_position + total_length])
  return result, true

}

consume_number :: proc(src: ^source_code.source_code_t) -> (string, bool) {
   if src == nil {
    return "", false
  }
  is_float:= bool(false)
  start_position:= src.pointer
  for !src.is_at_end {
    character:= rune(source_code.peek(src, 0))
    if character == '.' {
      if rune(source_code.peek(src, 1)) == '.' {
        break
      }
      if is_float {
        //HERE WE NEED TO 'err_unexpected_character'
        return "", false
      }
      is_float = true
    }
    if is_number(source_code.peek(src, 1)) {
      source_code.advance(src)
    } else {
      break
    }
  }
  total_length:= int(src.pointer - start_position + 1)
  result:= string(src.content[start_position : start_position + total_length])
  return result, true
}

is_next_word_match :: proc(src: source_code.source_code_t) -> bool {
  return true
}

consume_identifier :: proc(src: source_code.source_code_t) -> ^token.token_t {
  return token.generate_unknown_token()
}


consume_reserved_word :: proc(src: source_code.source_code_t) -> ^token.token_t {
  return token.generate_unknown_token()
}

scan :: proc(src: source_code.source_code_t) -> ^token_list.token_list_t {
  return token_list.token_list_new()
}
