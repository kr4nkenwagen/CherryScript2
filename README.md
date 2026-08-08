# Cherry — Language Reference & Project README

## What Cherry is
Cherry is a small, interpreted scripting language implemented in Odin. It emphasizes simplicity and readability while providing arrays, strings, functions, and common control flow constructs. This [...]

### Stack
- **Language(s):** Odin (implementation). Cherry is the language implemented by the repo.
- **Framework / runtime:** Cherry interpreter (CLI) written in Odin.
- **Notable tooling:** tree-sitter grammar (tree-sitter-cherry/), Odin toolchain for build/run.

## How the project is organized

```
src/
  main.odin                    # CLI / entrypoint
  scan/                        # Lexer / tokenizer
  parser/                      # Parser for expressions and statements
  evaluator/                   # AST evaluator / runtime
  object/                      # Object helpers (strings, files, arrays)
  predefined_functions/        # Built-in functions (print, len, etc.)
  vm/                          # VM frames & stack handling
  token/, token_list/          # Token helpers
  types/                       # Shared types & exit codes
  syntax/                      # Syntax node constructors
tree-sitter-cherry/            # tree-sitter grammar for Cherry
examples/                      # Example files demonstrating Cherry features
tests/                         # Test suite and utilities
```

**How it fits together**
- `main` reads source files -> `scan` tokenizes -> `parser` builds AST/program -> `evaluator` runs on a VM/frame stack. Predefined functions live in `predefined_functions` and are invoked by the e[...]

## How to build and run

Prerequisites
- Odin toolchain installed and on PATH.

Run a Cherry script directly (recommended for development):

```
odin run src/main.odin -- examples/hello.cherry
```

To build the interpreter into a binary (optional):
```
odin build -out:cherry .
# then run
./cherry examples/hello.cherry
```

(Exact build flags for your local environment may vary — the project uses plain Odin files; adjust commands for your Odin setup.)

## Language overview (concise reference)

This section documents Cherry's syntax and semantics as implemented in this repo.

Lexical elements
- Comments: start with `#` and continue to end of line.
- Identifiers: letters and underscores followed by alphanumerics/underscores.
- Numbers: integers and floating-point numbers (e.g., `12`, `12.34`, `.34`).
- Strings: single- or double-quoted string wrappers.
- Special punctuation: parentheses `()`, braces `{}`, brackets `[]`, comma `,`, dot `.`, semicolon/terminator, colon `:`.
- Operators: `+ - * / %`, comparisons `== != > < >= <=`, assignment `=`, compound `+=` etc., range/operator `..`, and arrow file ops `->` `<-`.
- Keywords: `and`, `break`, `class`, `const`, `continue`, `else`, `err`, `for`, `false`, `fn`, `if`, `null`, `nil`, `module`, `or`, `out`, `println`, `print`, `return`, `remove`, `super`, `this`, `true`, `var`, `while`, `len`, `in`, `key`, `rm`, `exists` (see `tree-sitter-cherry/grammar.js`).

Types
- INT, FLOAT, STRING, ARRAY, BOOL, NULL/NIL, FUNCTION, FILE (as seen in object modules and evaluator).

Control flow
- `if` / `else if` / `else` blocks
- `for` loops with three-part syntax: `for (init; condition; increment) { ... }`
- `while` loops
- `break` / `continue`

Functions
- Function definitions using `fn` keyword and calls are supported. Arguments are declared as `var` or `const` inside the function signature.
- Built-ins include `print`, `println`, `len`, `in`, and `key` (see `src/predefined_functions/predefined_functions.odin`).

Standard library (selected)
- print(obj) — prints an object
- println(obj) — prints object with newline
- len(obj) — returns integer length for strings/arrays where supported
- in() — read a line from stdin
- key() — read a single keystroke
- exists(file) — check if file exists
- rm(file) — remove/delete file

## Formal grammar (EBNF)

The grammar below is a concise EBNF derived from parser modules in `src/parser/` and token definitions. It's intended as a precise human-readable reference for Cherry's core syntax.

Note: terminals (tokens) are shown in ALL_CAPS or as literal punctuation. Nonterminals are in lower_case. `...` denotes repetition allowed. For the authoritative token list, see `tree-sitter-cherry/grammar.js`.

program      ::= { statement }

statement    ::= variable_decl
               | expression_statement
               | function_decl
               | if_statement
               | for_statement
               | while_statement
               | return_statement
               | out_statement
               | module_statement
               | TERMINATOR

variable_decl ::= ("var" | "const") identifier { "," (identifier ["=" expression]) } TERMINATOR

function_decl ::= "fn" identifier "(" [ function_args ] ")" ("{" program "}" | statement)
function_args ::= ( ("var" | "const") identifier ["=" expression] { "," ("var" | "const") identifier ["=" expression] } )

if_statement ::= "if" expression ("{" program "}") { "else if" expression ("{" program "}") } ["else" ("{" program "}")]
for_statement ::= "for" "(" line ";" line ";" line ")" "{" program "}"   ; three line() entries separated by semicolons
while_statement ::= "while" "(" expression ")" "{" program "}"
return_statement ::= "return" expression
out_statement ::= "out" expression
module_statement ::= "module" STRING_WRAPPER

expression_statement ::= expression

expression ::= equality

equality ::= comparison { ("==" | "!=") comparison }

comparison ::= term { (">" | "<" | ">=" | "<=") term }

logical_or ::= logical_and { "or" logical_and }

logical_and ::= equality { "and" equality }

term       ::= factor { ("+" | "-") factor }

factor     ::= unary { ("*" | "/" | "%") unary }

unary      ::= ("!" | "-") unary | primary

primary    ::= NUMBER
            | STRING_WRAPPER
            | "true" | "false" | "null" | "nil"
            | identifier [ function_call_or_index ]
            | "len" function_call_args
            | "in" function_call_args
            | "key" function_call_args
            | array_literal
            | "(" expression ")"

function_call_or_index ::= function_call | index_access
function_call ::= "(" [ argument_list ] ")"
argument_list ::= expression { "," expression }
index_access ::= "[" expression "]"

array_literal ::= "[" [ expression { "," expression } ] "]"

identifier ::= IDENTIFIER
NUMBER ::= integer | float
integer ::= DIGITS
float ::= DIGITS "." DIGITS | "." DIGITS

DIGITS ::= DIGIT { DIGIT }
DIGIT ::= "0" | "1" | ... | "9"

TERMINATOR ::= semicolon | newline

Comments and whitespace are ignored by the scanner.


## Examples (inline and in examples/)
Below are runnable examples and the path to example files added under `examples/`.

### Basic Examples

1) Hello world — `examples/hello.cherry`
```
println("Hello, Cherry")
```

2) Variables & arithmetic — `examples/variables.cherry`
```
var a = 10
var b = 20
println(a + b)
```

3) Functions — `examples/functions.cherry`
```
fn add(var x, var y) {
    return x + y
}
println(add(5, 6))
```

4) Arrays & len — `examples/arrays.cherry`
```
var arr = [1, 2, 3]
println(len(arr))
println(arr[0])
```

5) Floating point and nested calls — `examples/nested_len.cherry`
```
# nested expression with len in a comparison
println(len("abc") == 3)
# float value example
var f = 12.34
println(f)
```

### Real-World Examples

6) **Grade Calculator** — `examples/grade_calculator.cherry`
   - Processes student scores and computes average
   - Uses loops and functions to aggregate data
   - Demonstrates conditional logic for letter grades

7) **CSV Data Processing** — `examples/csv_processor.cherry`
   - Parses a simple dataset (student names and scores)
   - Demonstrates array manipulation and filtering
   - Useful for understanding data aggregation patterns

8) **Temperature Converter** — `examples/temperature_converter.cherry`
   - Converts temperature between Celsius and Fahrenheit
   - Shows function composition and nested conditionals
   - Practical real-world conversion use case

9) **Word Frequency Counter** — `examples/word_frequency.cherry`
   - Counts word occurrences in a text array
   - Demonstrates array searching and aggregation
   - Shows practical text analysis patterns

10) **Bank Account Simulator** — `examples/bank_account.cherry`
    - Simulates basic account operations (deposit, withdraw, balance inquiry)
    - Shows state management and transaction logging
    - Demonstrates practical business logic with error handling

To run any example:
```
odin run src/main.odin -- examples/hello.cherry
```

## Notes for contributors
- Lexer: `src/scan/scan.odin` implements tokenization; changes there should be mirrored in `tree-sitter-cherry/grammar.js`.
- Keywords: Check `tree-sitter-cherry/grammar.js` for authoritative keyword list.
- Parser: `src/parser/*.odin` contains productions. `passed_function_args` is the helper used to parse call argument lists.
- Evaluator: `src/evaluator/*` executes AST nodes and uses objects from `src/object`.

## Acknowledgements
This README and grammar were produced by inspecting the repository source files. For deeper changes (new syntax, new runtime types), please add tests under `examples/` and open a PR with ch[...]
