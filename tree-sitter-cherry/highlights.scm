; ====================================================================
; Cherry Language Highlighting Queries
; ====================================================================

; --- Comments & Literals ---
(comment) @comment
(string) @string
(number) @number

; --- Built-in Constants & Booleans ---
[
  "true"
  "false"
] @boolean

"null" @constant.builtin

; --- Built-in Functions & Commands ---
[
  "print"
  "println"
  "out"
  "err"
  "len"
  "remove"
  "rm"
  "exists"
  "sleep"
  "time"
  "key"
  "clr"
] @function.builtin

; --- Control Flow Keywords ---
[
  "if"
  "else"
] @keyword.conditional

[
  "for"
  "while"
  "break"
  "continue"
  "in"
] @keyword.repeat

"return" @keyword.return
"fn" @keyword.function

; --- Storage & Scope Keywords ---
[
  "var"
  "const"
  "global"
  "module"
] @keyword

; Catch-all for any other keywords
(keyword) @keyword

; --- Operators & Punctuation ---
(operator) @operator

[
  "("
  ")"
  "{"
  "}"
  "["
  "]"
] @punctuation.bracket

[
  ","
  ":"
  "."
  ";"
] @punctuation.delimiter

; --- Identifiers ---
(identifier) @variable
