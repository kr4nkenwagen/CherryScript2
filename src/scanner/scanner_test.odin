package scan

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:testing"
import "../grammar"
import "../source_code"
import "../token"
import "../token_list"
import "../types"

temp_dir_counter := 0

make_temp_dir :: proc() -> string {
	temp_dir_counter += 1
	suffix := fmt.tprintf("cherry_scanner_%d", temp_dir_counter)
	td, _ := os.temp_dir(context.allocator)
	defer delete(td)
	dir, _ := filepath.join([]string{td, suffix})
	os.make_directory(dir)
	return dir
}

scan_source_list :: proc(t: ^testing.T, content: string) -> (^types.token_list_t, types.exit_codes) {
	src, _ := source_code.create(content)
	return run(src)
}

types_of :: proc(list: ^types.token_list_t) -> []types.token_type_t {
	out: []types.token_type_t = make([]types.token_type_t, list.length)
	for i in 0 ..< list.length {
		out[i] = list.list[i].type
	}
	return out
}

literals_of :: proc(list: ^types.token_list_t) -> []string {
	out: []string = make([]string, list.length)
	for i in 0 ..< list.length {
		out[i] = list.list[i].literal
	}
	return out
}

meaningful_types :: proc(list: ^types.token_list_t) -> []types.token_type_t {
	full := types_of(list)
	defer delete(full)
	n := len(full)
	if n >= 2 && full[n - 1] == .END_OF_FILE && full[n - 2] == .TERMINATOR {
		n -= 2
	}
	out: []types.token_type_t = make([]types.token_type_t, n)
	for i in 0 ..< n {
		out[i] = full[i]
	}
	return out
}

expect_types :: proc(t: ^testing.T, list: ^types.token_list_t, want: []types.token_type_t) {
	got := meaningful_types(list)
	defer delete(got)
	if len(got) != len(want) {
		testing.expectf(t, false, "token count mismatch: got %d want %d\ngot=%v\nwant=%v", len(got), len(want), got, want)
		return
	}
	for i in 0 ..< len(got) {
		if got[i] != want[i] {
			testing.expectf(t, false, "token %d mismatch: got %v want %v", i, got[i], want[i])
			return
		}
	}
}

@(test)
run_nil_src :: proc(t: ^testing.T) {
	_, code := run(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER, "run(nil) wrong code")
}

@(test)
run_keywords :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "if(x)")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IF, .LEFT_PAREN, .IDENTIFIER, .RIGHT_PAREN})
}

@(test)
run_keyword_for_var_fn :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "for(var i = 0; i < 3; i += 1)")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {
		.FOR, .LEFT_PAREN, .VAR, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR,
		.IDENTIFIER, .LESS, .NUMBER, .TERMINATOR,
		.IDENTIFIER, .PLUS_EQUAL, .NUMBER, .RIGHT_PAREN,
	})
}

@(test)
run_keyword_const_return :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "const x = 1 return x\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.CONST, .IDENTIFIER, .EQUAL, .NUMBER, .RETURN, .IDENTIFIER})
}

@(test)
run_keyword_booleans :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "true false\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.TRUE, .FALSE})
}

@(test)
run_keyword_elif_else :: proc(t: ^testing.T) {
list, code := scan_source_list(t, "if(1) {} elif(2) {} else {}\n")
	defer token_list.remove(list)
	testing.expect(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {
		.IF, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .LEFT_BRACE, .TERMINATOR, .RIGHT_BRACE,
		.ELSE_IF, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .LEFT_BRACE, .TERMINATOR, .RIGHT_BRACE,
		.ELSE, .LEFT_BRACE, .TERMINATOR, .RIGHT_BRACE,
	})
}

@(test)
run_keyword_after_dot_is_identifier :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "x.len\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IDENTIFIER, .DOT, .IDENTIFIER})
}

@(test)
run_identifier_and_global :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "global const args = [\"a\"]")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.GLOBAL, .CONST, .IDENTIFIER, .EQUAL, .LEFT_BRACKET, .STRING_WRAPPER, .RIGHT_BRACKET})
}

@(test)
run_number_integer :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "42\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.NUMBER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[0] == "42", "number literal mismatch: %q", lit[0])
}

@(test)
run_number_float :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "3.14\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.NUMBER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[0] == "3.14", "float literal mismatch: %q", lit[0])
}

@(test)
run_number_negative :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "-7\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.NUMBER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[0] == "-7", "negative literal mismatch: %q", lit[0])
}

@(test)
run_number_dot_prefix :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "a = .5\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IDENTIFIER, .EQUAL, .NUMBER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[2] == ".5", "dot literal mismatch: %q", lit[2])
}

@(test)
run_number_range_not_float :: proc(t: ^testing.T) {
list, code := scan_source_list(t, "a..b\n")
	defer token_list.remove(list)
	testing.expect(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IDENTIFIER, .DOT, .DOT, .IDENTIFIER})
}

@(test)
run_string_literal :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "\"hello\"\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.STRING_WRAPPER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[0] == "hello", "string literal mismatch: %q", lit[0])
}

@(test)
run_string_escapes :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "\"a\\nb\\tc\\\"d\\\\\"\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.STRING_WRAPPER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[0] == "a\nb\tc\"d\\", "escape literal mismatch: %q", lit[0])
}

@(test)
run_char_wrapper :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "'x'\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.STRING_WRAPPER})
	lit := literals_of(list)
	defer delete(lit)
	testing.expectf(t, lit[0] == "x", "char literal mismatch: %q", lit[0])
}

@(test)
run_unterminated_string_error :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, `"oops`)
	defer token_list.remove(list)
	testing.expectf(t, code == .OUT_OF_BOUNDS_IN_SOURCE_CODE_PEEK, "unterminated string wrong code: %v", code)
}

@(test)
run_symbols :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "(){}[]\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {
		.LEFT_PAREN, .RIGHT_PAREN,
		.LEFT_BRACE, .TERMINATOR, .RIGHT_BRACE,
		.LEFT_BRACKET, .RIGHT_BRACKET,
	})
}

@(test)
run_operators :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "a -= b >= c == d && e\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {
		.IDENTIFIER, .MINUS_EQUAL, .IDENTIFIER, .GREATER_EQUAL, .IDENTIFIER,
		.EQUAL_EQUAL, .IDENTIFIER, .AND, .IDENTIFIER,
	})
}

@(test)
run_symbol_special :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "a :^ b .. c -> d <- e @ f $ g\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {
		.IDENTIFIER, .COLON_HAT, .IDENTIFIER, .DOT, .DOT, .IDENTIFIER,
		.MINUS, .GREATER, .IDENTIFIER, .LESS, .MINUS, .IDENTIFIER,
		.AT, .IDENTIFIER, .EXECUTE, .IDENTIFIER,
	})
}

@(test)
run_comment_line :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "# whole line comment\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {})
}

@(test)
run_comment_between_code :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "x = 1 # trailing comment\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IDENTIFIER, .EQUAL, .NUMBER})
}

@(test)
run_statements_keep_interior_terminator :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "x = 1\ny = 2\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .IDENTIFIER, .EQUAL, .NUMBER})
}

@(test)
run_terminators_deduped :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "a\n\n\nb\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IDENTIFIER, .TERMINATOR, .IDENTIFIER})
}

@(test)
run_empty_handles_auto_tail :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {})
}

@(test)
run_brace_newline_inserts_terminator :: proc(t: ^testing.T) {
	list, code := scan_source_list(t, "if(x) }\n")
	defer token_list.remove(list)
	testing.expectf(t, code == .OK, "run returned non-OK")
	expect_types(t, list, {.IF, .LEFT_PAREN, .IDENTIFIER, .RIGHT_PAREN, .TERMINATOR, .RIGHT_BRACE})
}

@(test)
consume_module_imports_file :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	lib_path, _ := filepath.join({dir, "lib.cherry"})
	defer delete(lib_path)
	werr := os.write_entire_file(lib_path, "from_lib := 9")
	testing.expectf(t, werr == nil, "failed to write lib")

	src, _ := source_code.create(`module "lib.cherry"
main_body
`)
	defer source_code.remove(src)
	src.location = dir

	_, code := run(src)
	testing.expectf(t, code == .OK, "consume_module import returned non-OK: %v", code)
	testing.expectf(t, strings_has(src.content, "from_lib := 9"), "module content not embedded")
	has_entry := false
	for sf in src.included_sources {
		if strings_has(sf.name, "lib.cherry") do has_entry = true
	}
	testing.expectf(t, has_entry, "module not tracked in included_sources")
}

@(test)
is_number_test :: proc(t: ^testing.T) {
	digits := []rune{'0', '1', '5', '9'}
	nondigits := []rune{'a', '.', '-', ' ', '_'}
	for r in digits {
		testing.expectf(t, is_number(r), "is_number(%q) should be true", r)
	}
	for r in nondigits {
		testing.expectf(t, !is_number(r), "is_number(%q) should be false", r)
	}
}

@(test)
is_end_of_word_test :: proc(t: ^testing.T) {
	delims := []rune{'\n', '\t', ' ', ';', '[', ']', '(', ')', '{', '}', ':', '=', '+', '-', '/', '*', '!', '<', '>', '.', ','}
	for r in delims {
		testing.expectf(t, is_end_of_word(r), "is_end_of_word(%q) should be true", r)
	}
	words := []rune{'a', 'z', '0', '_'}
	for r in words {
		testing.expectf(t, !is_end_of_word(r), "is_end_of_word(%q) should be false", r)
	}
}

@(test)
consume_word_reads_up_to_delimiter :: proc(t: ^testing.T) {
	src, _ := source_code.create("hello world")
	defer source_code.remove(src)
	source_code.advance(src)
	word, code := consume_word(src)
	testing.expectf(t, code == .OK, "consume_word returned non-OK")
	testing.expectf(t, word == "hello", "consume_word mismatch: %q", word)
}

@(test)
consume_word_nil_src :: proc(t: ^testing.T) {
	_, code := consume_word(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_CONSUME_WORD, "consume_word(nil) wrong code")
}

@(test)
is_next_word_match_match :: proc(t: ^testing.T) {
	src, _ := source_code.create("module x")
	defer source_code.remove(src)
	source_code.advance(src)
	ok, code := is_next_word_match(src, "module")
	testing.expectf(t, code == .OK, "is_next_word_match non-OK code")
	testing.expectf(t, ok, "expected module match")
}

@(test)
is_next_word_match_no_partial :: proc(t: ^testing.T) {
	src, _ := source_code.create("forest")
	defer source_code.remove(src)
	source_code.advance(src)
	ok, code := is_next_word_match(src, "for")
	testing.expectf(t, code == .OK, "is_next_word_match non-OK code")
	testing.expectf(t, !ok, "should not match 'for' inside 'forest'")
}

@(test)
is_next_word_match_nil_src :: proc(t: ^testing.T) {
	_, code := is_next_word_match(nil, "for")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_IS_NEXT_WORD_MATCH, "is_next_word_match(nil) wrong code")
}

@(test)
handle_right_brace_inserts_terminator :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("x y")
	defer source_code.remove(src)
	ident, _ := token.create(src, .IDENTIFIER, "x")
	num, _ := token.create(src, .NUMBER, "1")
	token_list.add(list, ident)
	token_list.add(list, num)
	handle_right_brace(list, src)
	testing.expectf(t, list.length == 3, "expected two tokens + terminator, got %d", list.length)
	last := list.list[list.length - 1]
	testing.expectf(t, last.type == .TERMINATOR, "expected terminator after right brace")
}

@(test)
remove_dupe_terminators_collapses :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	toks_to_add := []types.token_type_t{.IDENTIFIER, .TERMINATOR, .TERMINATOR, .TERMINATOR, .IDENTIFIER}
	for tt in toks_to_add {
		tok, _ := token.create(nil, tt, "")
		token_list.add(list, tok)
	}
	remove_dupe_terminators(list)
	ty := types_of(list)
	defer delete(ty)
	term_count := 0
	for i in 0 ..< len(ty) {
		if ty[i] == .TERMINATOR do term_count += 1
	}
	testing.expectf(t, term_count == 1, "expected one terminator after dedupe, got %d", term_count)
}

@(test)
consume_symbols_nil_src :: proc(t: ^testing.T) {
	_, code := consume_symbols(nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_SYMBOL, "consume_symbols(nil) wrong code")
}

@(test)
consume_string_nil_src :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	_, code := consume_string(list, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SOURCE_CODE_PEEK, "consume_string(nil) wrong code: %v", code)
}

@(test)
extract_string_nil_src :: proc(t: ^testing.T) {
	_, code := extract_string(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_STRING, "extract_string(nil) wrong code")
}

@(test)
consume_comment_nil_src :: proc(t: ^testing.T) {
	_, code := consume_comment(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_COMMENT, "consume_comment(nil) wrong code")
}

@(test)
consume_identifier_nil_src :: proc(t: ^testing.T) {
	_, code := consume_identifier(nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_IDENTIFIER, "consume_identifier(nil) wrong code")
}

@(test)
consume_number_nil_src :: proc(t: ^testing.T) {
	_, code := consume_number(nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_NUMBER, "consume_number(nil) wrong code")
}

@(test)
consume_keyword_converts_and_guards_dot :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("x")
	defer source_code.remove(src)
	kw, _ := token.create(src, .IDENTIFIER, "if")
	plain, _ := token.create(src, .IDENTIFIER, "foo")
	dot, _ := token.create(src, .DOT, ".")
	len_after_dot, _ := token.create(src, .IDENTIFIER, "len")
	token_list.add(list, kw)
	token_list.add(list, plain)
	token_list.add(list, dot)
	token_list.add(list, len_after_dot)
	consume_keyword(list)
	expect_types(t, list, {.IF, .IDENTIFIER, .DOT, .IDENTIFIER})
}

@(test)
handle_right_newline_no_paren_adds_terminator :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("x")
	defer source_code.remove(src)
	ident, _ := token.create(src, .IDENTIFIER, "x")
	token_list.add(list, ident)
	consumed, code := handle_right_newline(list, src)
	testing.expectf(t, code == .OK, "handle_right_newline non-OK code")
	testing.expectf(t, consumed, "handle_right_newline should report consumed")
	testing.expectf(t, list.length == 2, "expected identifier + terminator, got %d", list.length)
	last := list.list[list.length - 1]
	testing.expectf(t, last.type == .TERMINATOR, "expected terminator, got %v", last.type)
}

@(test)
handle_right_newline_in_paren_skips_terminator :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("x  (a")
	defer source_code.remove(src)
	source_code.advance(src)
	source_code.advance(src)
	source_code.advance(src)
	source_code.advance(src)
	_, code := handle_right_newline(list, src)
	testing.expectf(t, code == .OK, "handle_right_newline non-OK code")
	testing.expectf(t, list.length == 0, "expected no terminator inside parens, got %d", list.length)
}

@(test)
append_list_tail_adds_terminator_and_eof :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("x")
	defer source_code.remove(src)
	ident, _ := token.create(src, .IDENTIFIER, "x")
	token_list.add(list, ident)
	append_list_tail(list)
	testing.expectf(t, list.length == 3, "expected ident+term+eof, got %d", list.length)
	testing.expectf(t, list.list[1].type == .TERMINATOR, "expected terminator at [1]")
	testing.expectf(t, list.list[2].type == .END_OF_FILE, "expected EOF at [2]")
}

@(test)
append_list_tail_preserves_existing_terminator :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("x")
	defer source_code.remove(src)
	term, _ := token.create(src, .TERMINATOR, ";")
	token_list.add(list, term)
	append_list_tail(list)
	testing.expectf(t, list.length == 2, "expected term+eof, got %d", list.length)
	testing.expectf(t, list.list[1].type == .END_OF_FILE, "expected single terminator then EOF at [1]")
}

@(test)
order_symbols_by_literal_length_sorts :: proc(t: ^testing.T) {
	orig := grammar.symbols
	order_symbols_by_literal_length()
	defer grammar.symbols = orig
	for i in 0 ..< len(grammar.symbols) - 1 {
		if len(grammar.symbols[i].literal) < len(grammar.symbols[i + 1].literal) {
			testing.expectf(t, false, "symbols not sorted at index %d: %q < %q", i, grammar.symbols[i].literal, grammar.symbols[i + 1].literal)
			return
		}
	}
}

@(test)
consume_comment_skips_whitespace :: proc(t: ^testing.T) {
	src, _ := source_code.create("  x")
	defer source_code.remove(src)
	source_code.advance(src)
	consumed, code := consume_comment(src)
	testing.expectf(t, code == .OK, "consume_comment non-OK code")
	testing.expectf(t, consumed, "whitespace should be consumed")
}

@(test)
consume_comment_consumes_comment :: proc(t: ^testing.T) {
	src, _ := source_code.create("# note")
	defer source_code.remove(src)
	source_code.advance(src)
	consumed, code := consume_comment(src)
	testing.expectf(t, code == .OK, "consume_comment non-OK code")
	testing.expectf(t, consumed, "comment should be consumed")
}

@(test)
consume_identifier_adds_token :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("hello world")
	defer source_code.remove(src)
	source_code.advance(src)
	consumed, code := consume_identifier(list, src)
	testing.expectf(t, code == .OK, "consume_identifier non-OK code")
	testing.expectf(t, consumed, "identifier should be consumed")
	testing.expectf(t, list.length == 1, "expected one token, got %d", list.length)
	testing.expectf(t, list.list[0].type == .IDENTIFIER, "expected identifier token")
	testing.expectf(t, list.list[0].literal == "hello", "literal mismatch: %q", list.list[0].literal)
}

@(test)
consume_number_adds_token :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("123 456")
	defer source_code.remove(src)
	source_code.advance(src)
	consumed, code := consume_number(list, src)
	testing.expectf(t, code == .OK, "consume_number non-OK code")
	testing.expectf(t, consumed, "number should be consumed")
	testing.expectf(t, list.length == 1, "expected one token, got %d", list.length)
	testing.expectf(t, list.list[0].type == .NUMBER, "expected number token")
	testing.expectf(t, list.list[0].literal == "123", "literal mismatch: %q", list.list[0].literal)
}

@(test)
consume_string_adds_token :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create(`"hi"`)
	defer source_code.remove(src)
	source_code.advance(src)
	consumed, code := consume_string(list, src)
	testing.expectf(t, code == .OK, "consume_string non-OK code")
	testing.expectf(t, consumed, "string should be consumed")
	testing.expectf(t, list.length == 1, "expected one token, got %d", list.length)
	testing.expectf(t, list.list[0].type == .STRING_WRAPPER, "expected string token")
	testing.expectf(t, list.list[0].literal == "hi", "literal mismatch: %q", list.list[0].literal)
}

@(test)
extract_string_reads_content :: proc(t: ^testing.T) {
	src, _ := source_code.create(`"abc"`)
	defer source_code.remove(src)
	source_code.advance(src)
	str, code := extract_string(src)
	testing.expectf(t, code == .OK, "extract_string non-OK code")
	testing.expectf(t, str == "abc", "extract_string mismatch: %q", str)
}

@(test)
consume_symbols_adds_token :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	src, _ := source_code.create("+=")
	defer source_code.remove(src)
	source_code.advance(src)
	consumed, code := consume_symbols(list, src)
	testing.expectf(t, code == .OK, "consume_symbols non-OK code")
	testing.expectf(t, consumed, "symbol should be consumed")
	testing.expectf(t, list.length == 1, "expected one token, got %d", list.length)
	testing.expectf(t, list.list[0].type == .PLUS_EQUAL, "expected plus-equal token")
}

@(test)
consume_module_nil_src :: proc(t: ^testing.T) {
	list, _ := token_list.create()
	defer token_list.remove(list)
	_, code := consume_module(list, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SCANNER_IS_NEXT_WORD_MATCH, "consume_module(nil) wrong code: %v", code)
}

strings_has :: proc(s, sub: string) -> bool {
	for i in 0 ..= len(s) - len(sub) {
		if s[i:i + len(sub)] == sub do return true
	}
	return false
}