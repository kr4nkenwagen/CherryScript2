package scan

import "../source_code"
import "../token"
import "../token_list"
import "core:unicode"
import "core:strings"

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

is_next_word_match :: proc(src: ^source_code.source_code_t, word: string) -> (bool, bool) {
  if src == nil {
    return false, false
  }
  if src.pointer + len(word) >= src.length {
    return false, true
  }
  if strings.to_lower(src.content[src.pointer : src.pointer + len(word)]) == string(word) {
    return true, true
  }
  return true, true
}

consume_identifier :: proc(src: ^source_code.source_code_t) -> (^token.token_t, bool) {
  if src == nil || unicode.is_alpha(source_code.peek(src, -1)){
    return nil, false
  }
  word, err:= consume_word(src)
  if err {
    return nil, false
  }
  return token.token_new(src, token.type_t.IDENTIFIER, word), true
}

match_specific_reserved_word :: proc(src: ^source_code.source_code_t, literal: string, token_type: token.type_t) -> (^token.token_t, bool) {
  match, err:= is_next_word_match(src, "and")
    if err {
    return nil, false
  }
  if match {
    word, err:= consume_word(src)
    if err {
      return nil, false
    }
    return token.token_new(src, token.type_t.AND, word), true
  }
  return nil, false
}

consume_reserved_word :: proc(src: ^source_code.source_code_t) -> (^token.token_t, bool) {
  if src == nil || unicode.is_alpha(source_code.peek(src, -1)) {
    return nil, false
  }
  character:= rune(source_code.peek(src, 0))
  switch(character) {
  case 'a': fallthrough
  case 'A': return match_specific_reserved_word(src, "AND", token.type_t.AND)
  case 'b': fallthrough
  case 'B': return match_specific_reserved_word(src, "BREAK", token.type_t.BREAK)
  case 'c': fallthrough
  case 'C': 
  case 'e': fallthrough
  case 'E':
  case 'f': fallthrough
  case 'F':
  case 'i': fallthrough
  case 'I':
  case 'n': fallthrough
  case 'N':
  case 'm': fallthrough
  case 'M':
  case 'o': fallthrough
  case 'O':
  case 'p': fallthrough
  case 'P':
    match, err:= is_next_word_match(src, "println")
    if err {
      return nil, false
    }
    word, _:= consume_word(src)
    if match {
      return token.token_new(src, token.type_t.PRINT_LINE, word), true
    }
    match, err = is_next_word_match(src, "print")
    if err {
      return nil, false
    }
    if match { 
      return token.token_new(src, token.type_t.PRINT, word), true
    }
  case 'r': fallthrough
  case 'R':
    match, err:= is_next_word_match(src, "return")
    if err {
      return nil, false
    }
    word, _:= consume_word(src)
    if match {
      return token.token_new(src, token.type_t.RETURN, word), true
    }
    match, err = is_next_word_match(src, "remove")
    if err {
      return nil, false
    }
    if match {
      return token.token_new(src, token.type_t.REMOVE, word), true
    }
  case 's': fallthrough
  case 'S':
    match, err:= is_next_word_match(src, "super")
    if err {
      return nil, false
    }
    word, _:= consume_word(src)
    return token.token_new(src, token.type_t.SUPER, word), true
  case 't': fallthrough
  case 'T':
    match, err:= is_next_word_match(src, "this")
    if err {
      return nil, false
    }
    word, _:= consume_word(src)
    if match {
      return token.token_new(src, token.type_t.THIS, word), true
    }
    else if word == "true" {
      return token.token_new(src, token.type_t.TRUE, word), true
    }
  case 'v': fallthrough
  case 'V':
    match, err:= is_next_word_match(src, "var")
    if err {
      return nil, false
    }
    word, _:= consume_word(src)
    return token.token_new(src, token.type_t.VAR, word), true

  case 'w': fallthrough
  case 'W':
    match, err:= is_next_word_match(src, "while")
    if err {
      return nil, false
    }
    word, _:= consume_word(src)
    return token.token_new(src, token.type_t.WHILE, word), true
  case '&':
    if source_code.peek(src, 1) == '&' {
      source_code.advance(src)
      source_code.advance(src)
      return token.token_new(src, token.type_t.AND, "&&"), true
    }
  case '|':
    if source_code.peek(src, 1) == '|' {
      source_code.advance(src)
      source_code.advance(src)
      return token.token_new(src, token.type_t.OR, "||"), true
    }
  }
  return nil, false
}

scan :: proc(src: source_code.source_code_t) -> ^token_list.token_list_t {
  return token_list.token_list_new()
}
