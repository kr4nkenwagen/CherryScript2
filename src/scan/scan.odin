package scan

import "../source_code"
import "../token"
import "../token_list"

consume_comment :: proc(src: source_code.source_code_t) {

}

consume_string :: proc(src: source_code.source_code_t) -> string {
  return ""
}

is_number :: proc(character: rune) -> bool {
  return true
}

is_end_of_word :: proc(character: rune) -> bool {
  return true
}

consume_word :: proc(src: source_code.source_code_t) -> string{
  return ""
}

consume_number :: proc(src: source_code.source_code_t) -> string{
  return ""
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
