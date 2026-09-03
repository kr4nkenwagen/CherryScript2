package source_code

import "core:fmt"
import "core:os"
import "core:path/filepath"
import "core:testing"
import "../types"

temp_dir_counter := 0

make_temp_dir :: proc() -> string {
	temp_dir_counter += 1
	suffix := fmt.tprintf("cherry_source_code_%d", temp_dir_counter)
	td, _ := os.temp_dir(context.allocator)
	defer delete(td)
	dir, _ := filepath.join([]string{td, suffix})
	os.make_directory(dir)
	return dir
}

@(test)
create_sets_defaults :: proc(t: ^testing.T) {
	src, code := create("hello world")
	defer remove(src)
	testing.expect(t, code == .OK, "create returned non-OK code")
	testing.expect(t, src.content == "hello world", "content mismatch")
	testing.expect(t, src.length == 11, "length mismatch")
	testing.expect(t, src.pointer == -1, "pointer should start at -1")
	testing.expect(t, src.line == 1, "line should start at 1")
	testing.expect(t, src.column == 1, "column should start at 1")
	testing.expect(t, !src.is_at_end, "is_at_end should be false")
	testing.expect(t, len(src.included_sources) == 0, "no source files should be included")
}

@(test)
create_with_path_adds_source_file :: proc(t: ^testing.T) {
	src, code := create("body", "main.cherry")
	defer remove(src)
	testing.expect(t, code == .OK, "create returned non-OK code")
	testing.expect(t, len(src.included_sources) == 1, "expected one included source")
	testing.expect(t, src.included_sources[0].name == "main.cherry", "source name mismatch")
	testing.expect(t, src.included_sources[0].imported_at_index == 0, "imported_at_index should be 0")
}

@(test)
create_clean_failure_returns_nil :: proc(t: ^testing.T) {
	src, code := create("body", "")
	testing.expect(t, code == .OK, "create returned non-OK code")
	testing.expect(t, src != nil, "create returned nil source")
	defer remove(src)
}

@(test)
add_args_empty :: proc(t: ^testing.T) {
	src, _ := create("x := 1")
	defer remove(src)
	code := add_args(src, {})
	testing.expect(t, code == .OK, "add_args empty returned non-OK code")
	testing.expect(t, src.content == "global const args = [];\nx := 1", "empty args content mismatch")
	testing.expect(t, src.length == len(src.content), "length not updated")
}

@(test)
add_args_single :: proc(t: ^testing.T) {
	src, _ := create("x")
	defer remove(src)
	code := add_args(src, {"foo"})
	testing.expect(t, code == .OK, "add_args single returned non-OK code")
	testing.expect(t, src.content == `global const args = ["foo"];` + "\n" + "x", "single args content mismatch")
	testing.expect(t, src.length == len(src.content), "length not updated")
}

@(test)
add_args_multiple :: proc(t: ^testing.T) {
	src, _ := create("x")
	defer remove(src)
	code := add_args(src, {"a", "b", "c"})
	testing.expect(t, code == .OK, "add_args multiple returned non-OK code")
	expected := `global const args = ["a","b","c"];` + "\n" + "x"
	testing.expect(t, src.content == expected, "multiple args content mismatch")
	testing.expect(t, src.length == len(src.content), "length not updated")
}

@(test)
add_args_escapes :: proc(t: ^testing.T) {
	src, _ := create("x")
	defer remove(src)
	code := add_args(src, {`a"b\c`})
	testing.expect(t, code == .OK, "add_args escapes returned non-OK code")
	expected := `global const args = ["a\"b\\c"];` + "\n" + "x"
	testing.expect(t, src.content == expected, "escape content mismatch, got=%q", src.content)
	testing.expect(t, src.length == len(src.content), "length not updated")
}

@(test)
from_repl_appends_semicolon :: proc(t: ^testing.T) {
	src, code := from_repl("println(1)")
	defer remove(src)
	testing.expect(t, code == .OK, "from_repl returned non-OK code")
	testing.expect(t, src.content == "println(1);", "content should append semicolon")
	testing.expect(t, src.pointer == -1, "pointer should be -1")
}

@(test)
from_file_reads_content_and_location :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	path, _ := filepath.join({dir, "script.cherry"})
	defer delete(path)
	body := "print_hi :: fn() { return 1 }"
	werr := os.write_entire_file(path, body)
	testing.expect(t, werr == nil, "failed to write test file")

	src, code := from_file(path)
	defer remove(src)
	testing.expect(t, code == .OK, "from_file should succeed")
	testing.expect(t, src.content == body, "content mismatch")
	testing.expect(t, len(src.location) > 0, "location should be set")
	testing.expect(t, src.length == len(body), "length mismatch")
	testing.expect(t, len(src.included_sources) == 1, "expected one included source")
}

@(test)
from_file_missing_returns_error :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	path, _ := filepath.join({dir, "does_not_exist.cherry"})
	defer delete(path)
	src, code := from_file(path)
	testing.expect(t, src == nil, "expected nil source on missing file")
	testing.expectf(t, code == .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_FROM_FILE, "wrong exit code, got=%v", code)
}

@(test)
get_cherry_files_in_dir_filters :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	files := []string{"a.cherry", "b.txt", "c.cherry", "d.log"}
	for f in files {
		p, _ := filepath.join({dir, f})
		werr := os.write_entire_file(p, "")
		testing.expectf(t, werr == nil, "failed to write %s", f)
		delete(p)
	}
	paths, code := get_cherry_files_in_dir(dir)
	defer delete(paths)
	testing.expect(t, code == .OK, "get_cherry_files_in_dir returned non-OK code")
	testing.expectf(t, len(paths) == 2, "expected two cherry files, got %d", len(paths))
}

@(test)
get_cherry_files_in_dir_bare_file :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	path, _ := filepath.join({dir, "solo.cherry"})
	defer delete(path)
	werr := os.write_entire_file(path, "")
	testing.expect(t, werr == nil, "failed to write test file")
	paths, code := get_cherry_files_in_dir(path)
	defer delete(paths)
	testing.expect(t, code == .OK, "get_cherry_files_in_dir returned non-OK code")
	testing.expect(t, len(paths) == 1, "expected single path")
	testing.expect(t, paths[0] == path, "bare file path mismatch")
}

@(test)
import_file_embeds_and_tracks :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	path, _ := filepath.join({dir, "lib.cherry"})
	defer delete(path)
	werr := os.write_entire_file(path, "lib_body")
	testing.expect(t, werr == nil, "failed to write lib")

	target, _ := create("main_body", "main.cherry")
	defer remove(target)
	target.location = dir
	target.pointer = len(target.content)

	code := import_file(target, "lib.cherry")
	testing.expect(t, code == .OK, "import_file returned non-OK code")
	testing.expect(t, target.content == "main_body\nlib_body\n", "content not embedded")
	testing.expect(t, target.length == len(target.content), "length not updated")
	testing.expect(t, len(target.included_sources) == 2, "expected two included sources")
}

@(test)
import_file_ignores_duplicate :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	path, _ := filepath.join({dir, "lib.cherry"})
	defer delete(path)
	werr := os.write_entire_file(path, "lib_body")
	testing.expect(t, werr == nil, "failed to write lib")

	target, _ := create("main_body", "main.cherry")
	defer remove(target)
	target.location = dir
	target.pointer = len(target.content)

	first := import_file(target, "lib.cherry")
	pre_len := len(target.included_sources)
	second := import_file(target, "lib.cherry")
	testing.expect(t, first == .OK, "first import should succeed")
	testing.expect(t, second == .OK, "duplicate import should succeed")
	testing.expect(t, len(target.included_sources) == pre_len, "duplicate import added a source")
}

@(test)
import_file_missing_returns_error :: proc(t: ^testing.T) {
	dir := make_temp_dir()
	defer os.remove_all(dir)
	target, _ := create("body", "main.cherry")
	defer remove(target)
	target.location = dir
	code := import_file(target, "no_such_lib.cherry")
	testing.expectf(t, code == .FAILED_TO_READ_SOURCE_CODE_FILE_IN_SOURCE_CODE_IMPORT_FILE, "wrong exit code, got=%v", code)
}

@(test)
advance_increments_state :: proc(t: ^testing.T) {
	src, _ := create("ab\ncd")
	defer remove(src)
	advance(src)
	testing.expect(t, src.pointer == 0, "pointer should be 0 after first advance")
	testing.expect(t, src.column == 2, "column should be 2")
	testing.expect(t, src.line == 1, "line should be 1")
	advance(src)
	testing.expect(t, src.pointer == 1, "pointer should be 1")
	advance(src)
	testing.expect(t, src.line == 2, "line should be 2 after newline")
	testing.expect(t, src.column == 1, "column should reset to 1 after newline")
}

@(test)
advance_multiple_count :: proc(t: ^testing.T) {
	src, _ := create("abcd")
	defer remove(src)
	advance(src, 2)
	testing.expect(t, src.pointer == 1, "pointer should be 1 after advancing 2")
}

@(test)
advance_past_end_sets_eof :: proc(t: ^testing.T) {
	src, _ := create("a")
	defer remove(src)
	_, c1 := advance(src)
	testing.expect(t, c1 == .OK, "first advance should succeed")
	_, c2 := advance(src)
	testing.expect(t, c2 == .EOF_IN_SOURCE_CODE_REACHED_IN_SOURCE_CODE_ADVANCE, "second advance should hit EOF")
	testing.expect(t, src.is_at_end, "is_at_end should be set")
}

@(test)
advance_after_eof_returns_already_reached :: proc(t: ^testing.T) {
	src, _ := create("a")
	defer remove(src)
	advance(src)
	advance(src)
	_, c := advance(src)
	testing.expect(t, c == .EOF_ALREADY_TRIGGERED_REACHED_IN_SOURCE_CODE_ADVANCE, "advance after EOF wrong code")
}

@(test)
advance_nil_src :: proc(t: ^testing.T) {
	_, c := advance(nil)
	testing.expect(t, c == .OBJECT_IS_NIL_IN_SOURCE_CODE_ADVANCE, "nil advance wrong code")
}

@(test)
peek_various_distances :: proc(t: ^testing.T) {
	src, _ := create("abcdef")
	defer remove(src)
	for i := 0; i < 3; i += 1 do advance(src)
	ch0, c0 := peek(src, 0)
	testing.expect(t, c0 == .OK, "peek 0 should succeed")
	testing.expect(t, ch0 == 'c', "peek 0 char mismatch")
	chp, _ := peek(src, 2)
	testing.expect(t, chp == 'e', "peek +2 char mismatch")
	chn, _ := peek(src, -1)
	testing.expect(t, chn == 'b', "peek -1 char mismatch")
}

@(test)
peek_out_of_bounds :: proc(t: ^testing.T) {
	src, _ := create("abc")
	defer remove(src)
	for i := 0; i < 3; i += 1 do advance(src)
	_, c := peek(src, 1)
	testing.expect(t, c == .OUT_OF_BOUNDS_IN_SOURCE_CODE_PEEK, "peek beyond end wrong code")
	_, cn := peek(src, -4)
	testing.expect(t, cn == .OUT_OF_BOUNDS_IN_SOURCE_CODE_PEEK, "peek before start wrong code")
}

@(test)
peek_nil_src :: proc(t: ^testing.T) {
	_, c := peek(nil)
	testing.expect(t, c == .OBJECT_IS_NIL_IN_SOURCE_CODE_PEEK, "nil peek wrong code")
}

@(test)
remove_cleans_up :: proc(t: ^testing.T) {
	src, _ := create("abc")
	c := remove(src)
	testing.expect(t, c == .OK, "remove should return OK")
}

@(test)
remove_nil_src :: proc(t: ^testing.T) {
	c := remove(nil)
	testing.expect(t, c == .OBJECT_IS_NIL_IN_SOURCE_CODE_REMOVE, "nil remove wrong code")
}