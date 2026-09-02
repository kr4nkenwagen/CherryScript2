# Cherry — Language Reference & Project README

## What Cherry is

Cherry is an interpreted scripting language implemented in Odin. It combines a simple, readable syntax with a practical standard library — including arrays, strings, JSON, file I/O, a full HTTP client, math and time libraries, and terminal control. It ships with an interactive REPL, inline ("pipe") execution, and a multi-level debugger.

### Stack

- **Language(s):** Odin (implementation). Cherry is the language implemented by the repo.
- **Framework / runtime:** Cherry interpreter (CLI) written in Odin, with a VM/frame-stack evaluator.
- **Notable tooling:** tree-sitter grammar (`tree-sitter-cherry/`), libcurl-backed HTTP client, built-in test framework and performance benchmarking, Odin toolchain for build/run.

## How the project is organized

```
src/
  main.odin                    # CLI / entrypoint, argument parsing
  scanner/                     # Lexer / tokenizer
  parser/                      # Parser productions (if, for, math, http, ...)
  evaluator/                   # AST evaluator / runtime
  format/                      # `cherry format` token-stream pretty-printer
  object/                      # Object helpers (string, files, arrays, json, http)
  vm/                          # VM frames & stack handling
  stack/                       # Variable scope stack
  types/                       # Shared types, exit codes, tokens
  grammar/                     # Keyword & symbol tables
  syntax/                      # Syntax node constructors
  program/                     # Program block constructors
  token/                       # Token helpers
  token_list/                  # Token list helpers
  source_code/                 # Source file loading & module imports
  repl/                        # REPL, line editor, history, highlighting
  sys/                         # Error reporting, ANSI paint/highlighting
  http/                        # libcurl HTTP client (all methods)
  debug/                       # AST printer, token dumper, eval inspector
tree-sitter-cherry/            # tree-sitter grammar for Cherry
examples/                      # Example files demonstrating Cherry features
tests/                         # Test suite, output snapshots, benchmarks
doc/                           # Per-feature markdown documentation
```

**How it fits together**

`main` reads source files -> `scanner` tokenizes -> `parser` builds an AST/program -> `evaluator` runs it on a VM/frame stack. `http/` provides the network client used by `http.*` calls. `object/` holds the runtime values (int, float, string, array, bool, null, function, file, json). Modual imports are resolved by `source_code`. With no file arguments, `main` launches the interactive `repl`.

## How to build and run

Prerequisites

- Odin toolchain installed and on PATH.
- libcurl headers/libraries for the HTTP client.

Build the interpreter into a binary (recommended):

```
odin build src -o:speed -out:cherry
```

Then run a Cherry script:

```
./cherry examples/hello.cherry
```

You can also run without an explicit binary as part of development:

```
odin run src/main.odin -- examples/hello.cherry
```

### Running modes

```
./cherry                          # launch the interactive REPL
./cherry examples/hello.cherry    # execute a script file
./cherry a.cherry b.cherry        # execute multiple script files
./cherry println("hi")            # pipe mode: run inline code (no file)
./cherry examples/fizzbuzz.cherry println("extra")   # mix files + inline code
```

### Formatting source

The interpreter also exposes a `format` subcommand that pretty-prints Cherry:
idempotent 4-space indentation, aligned braces, one statement per line, and
canonical operator spacing. Because the formatter is token-based, it also
strips comments.

```
./cherry format file.cherry       # write formatted output to stdout
./cherry format -w file.cherry    # format in place (overwrite the file)
./cherry format < file.cherry     # read stdin, write stdout (IDE use)
```

### Debug modes

Pass `-debug <0-3>` (or `debug <0-3>`) before your script to enable a debug level:

| Level | Flag value | Behavior |
|-------|-----------|----------|
| 0     | `0`       | Normal execution (off) |
| 1     | `1`       | Dump the token list (colorized table) |
| 2     | `2`       | Print the AST tree |
| 3     | `3`       | Interactive step-through inspector (token timeline, source, stack, logs) |

Example:

```
./cherry -debug 2 examples/hello.cherry
```

## Language overview (concise reference)

This section documents Cherry's syntax and semantics as implemented in this repo. Per-feature detail lives in `doc/`.

### Lexical elements

- **Comments:** start with `#` and continue to end of line.
- **Identifiers:** letters and underscores followed by alphanumerics/underscores.
- **Numbers:** integers and floating-point numbers (e.g. `12`, `12.34`, `.34`).
- **Strings:** single- or double-quoted. Escape sequences: `\n`, `\t`, `\\`.
- **Keywords:** `var`, `const`, `global`, `fn`, `if`, `elif`, `else`, `for`, `while`, `break`, `continue`, `return`, `true`, `false`, `null`, `print`, `println`, `out`, `err`, `in`, `key`, `len`, `exists`, `rm`, `remove`, `sleep`, `clr`, `time`, `module`, `json`, `http`, `string`, `math`, `terminal`, `execute`.
- **Operators:** arithmetic `+ - * / %` with compound forms `+= -= *= /=`, comparisons `== != > < >= <=`, logical `&& || !`, assignment `=`, and specialized operators:
  - `..` string concatenation
  - `:` left substring, `:^` right substring
  - `->` file read, `<-` file write
  - `@` file reference
  - `$` system command execution

### Types

INT, FLOAT, STRING, ARRAY, BOOL, NULL, FUNCTION, FILE, JSON.

### Variables & scope

- `var` — mutable variable.
- `const` — immutable variable (reassignment is an error).
- `global var` / `global const` / `global fn` — declared in the shared global scope, visible across all function scopes.
- Multiple variables can be declared on one line: `var a, b, c` with optional initializers.

### Control flow

- `if (cond) { ... } elif (cond) { ... } else { ... }`
- `for (init; condition; increment) { ... }` — C-style three-part loop.
- `for (condition) { ... }` — while-style loop.
- `while (condition) { ... }` — explicit while loop.
- `break` / `continue` inside loops.

### Functions

- Defined with `fn name(var a, const b) { ... }`. Parameters are declared `var` or `const`.
- Default parameter values supported: `fn f(var x = 10) { ... }`.
- Recursion and nested function calls supported.
- `return expr` returns a value.

### Modules

- `module "filename.cherry"` inserts the file's contents at the current position.
- Directory imports are supported; duplicates are tracked and skipped.

## Standard library

### Output & input

- `print(obj)` / `println(obj)` — print (with/without newline). Output supports inline hex colors, e.g. `"[#cc6685]text[#] end"`.
- `out expr` — statement-form print (no parentheses).
- `err expr` — print to stderr.
- `in()` — read a line from stdin.
- `key()` — read a single keystroke.

### String library

- `string.contains(str, search)`
- `string.first_index_of(str, search)`
- `string.last_index_of(str, search)`
- `string.first_index_of_from(str, search, start)`
- `string.trim_start(str)` / `string.trim_end(str)` / `string.trim(str)`
- `string.to_upper(str)` / `string.to_lower(str)`
- `string.pad_start(str, count)` / `string.pad_end(str, count)`
- `string.replace_all(str, old, new)`

String operators: `a .. b` concat, `str:n` first n chars, `str:^n` last n chars, `str + x` join, `str - x` strip instances, `str * n` repeat, `str / n` truncate, `str % n` last n chars.

### Math library

- Constants: `math.pi`, `math.tau`.
- Functions: `math.max`, `math.min`, `math.min_max`/`math.clamp`, `math.abs`, `math.sqrt`, `math.sign`, `math.floor`, `math.ceil`, `math.round`, `math.trunc`, `math.random`, `math.random_range`, `math.lerp`, `math.sin`, `math.cos`, `math.tan`, `math.asin`, `math.acos`, `math.atan`, `math.atan2`, `math.log`, `math.hypot`.

### JSON

- `json("...")` — parse a JSON string into a JSON object.
- `json(@"file.json")` — load from a file (auto-creates with `{}` if missing; auto-persists on mutation).
- Members accessed via the `.` operator; deeply nested objects supported.
- Values serialize back to JSON via print/println (pretty-printed).

### HTTP client

- `http.get(url)`, `http.post(url, ...)`, `http.put`, `http.patch`, `http.delete`, `http.head`, `http.options`, `http.trace`, `http.connect`, `http.update`.
- Arguments: either a URL string or a JSON config `{ "url": ..., "body": ..., "head": ... }`.
- Returns a structured JSON response with `body` (auto-parsed as JSON when possible) and `head`.

### Time & terminal

- `time.year`, `time.month`, `time.month_name`, `time.day`, `time.hour`, `time.minute`, `time.second`, `time.millisecond`, `time.microsecond`, `time.nanosecond`, `time.weekday`, `time.day_of_week`, `time.day_of_year`, `time.execution_time`.
- `sleep <expr>` — pause for the given number of seconds (int or float).
- `terminal.width`, `terminal.height`, `terminal.pixel_width`, `terminal.pixel_height`.
- `clr` — clear the terminal.

### File I/O

- `@"filename"` — create a file reference.
- `file->index` — read a line by index.
- `file<-index = "text"` — write a line in place.
- `len(file)` — number of lines.
- `exists(file)` — file existence check.
- `rm file` / `remove file` — delete a file (also works on file-backed JSON).

### System commands

- `$"command"` — run a shell command; returns a JSON object with `stdout`, `stderr`, and `exit_code`.

### Built-in functions

- `len(obj)` — length of strings/arrays/files.
- `key()` — read a keystroke; `in()` — read a line.

## Examples (in examples/)

Categorized example programs, all runnable with `./cherry examples/<file>`:

- **Basics:** `hello.cherry`, `hello_world.cherry`, `variables.cherry`, `arrays.cherry`, `nested_len.cherry`
- **Control flow:** `control_flow.cherry`, `fizzbuzz.cherry`, `fibonacci.cherry`, `number_guessing.cherry`
- **Functions:** `functions.cherry`, `grade_calculator.cherry`, `temperature_converter.cherry`, `word_frequency.cherry`, `csv_processor.cherry`, `bank_account.cherry`
- **Applied:** `http_request.cherry` (HTTP client), `file_logger.cherry` (file I/O)

## Tests & benchmarks

The test suite is written in Cherry itself using the assertion library in `tests/utils/`. Both suite runners accept an optional `CHERRY_BIN` environment variable to use a prebuilt binary instead of rebuilding:

```
CHERRY_BIN=/path/to/cherry tests/run.sh
```

### Run the full test suite

```
tests/run.sh
```

This builds the interpreter, then runs:
1. **E2E tests** (`tests/e2e/`) — feature correctness across arithmetic, arrays, control flow, functions, strings, math, JSON, HTTP, files, terminal, time, globals, and pipe mode (via `tests/testrunner.cherry`).
2. **Output snapshot tests** (`tests/output/`) — verifies `print`/`println`/`out`/`err` stdout/stderr behavior.
3. **Error-exit-code tests** (`tests/errors/`) — each script is expected to fail with a specific exit code (encoded in the filename).
4. **Example smoke tests** (`tests/examples_run/`) — runs every non-interactive example and asserts it exits 0.
5. **Performance benchmarks** — runs `tests/perf_runner.cherry` and asserts each benchmark stays under its configured threshold.

Failures are reported per-suite; the runner exits nonzero if any unexpected failure occurs. Tests listed in `tests/expected_failures.txt` are excluded from the failure tally (see header of `tests/run.sh`).

### Run only the performance benchmarks

```
tests/perf.sh
```

Runs the benchmark suite (100k iterations per benchmark) and records results to `tests/perf/history/history.csv` (and `tests/perf/history/latest.csv`), then prints a comparison against the last 100 runs per benchmark (current vs. average/min/max/delta). Asserts each benchmark stays under its threshold.

## Notes for contributors

- **Scanner:** `src/scanner/` tokenizes input; keyword/symbol tables live in `src/grammar/grammar.odin`. Changes here should be mirrored in `tree-sitter-cherry/grammar.js`.
- **Parser:** `src/parser/*.odin` contains one file per production (`parse_if`, `parse_for`, `parse_math`, `parse_http`, `parse_json`, etc.).
- **Evaluator:** `src/evaluator/*` executes AST nodes (an `eval_*` file per feature). Runtime values live in `src/object/`.
- **Formatter:** `cherry format` (`src/format/format.odin`) is a token-stream pretty-printer; it does not use the parser and is comment-stripping by design.
- **HTTP:** network calls are implemented in `src/http/` on top of `vendor:curl`.
- **Error codes:** there are 353 distinct exit codes in `src/types/exit_codes.odin`; new failures should be added there and exercised via a `tests/errors/` script.

## Documentation

Per-feature markdown documentation lives in `doc/` (37 files covering data types, variables, control flow, functions, I/O, APIs like `math`, `http`, `json`, and `time`).

## Acknowledgements

This README was produced by inspecting the repository source files, the test suite, and the per-feature docs. For deeper changes (new syntax, new runtime types), add e2e and error tests under `tests/`, an example under `examples/`, document it in `doc/`, and update the tree-sitter grammar in `tree-sitter-cherry/`.
