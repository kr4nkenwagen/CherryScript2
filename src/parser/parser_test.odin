package parser

import "core:testing"
import "../program"
import "../scanner"
import "../source_code"
import "../syntax"
import "../token"
import "../token_list"
import "../types"

build_tokens :: proc(ts: []types.token_type_t, ls: []string) -> (list: ^types.token_list_t, code: types.exit_codes) {
	list = new(types.token_list_t)
	list.length = 0
	list.pointer = 0
	for i in 0 ..< len(ts) {
		tok, _ := token.create(nil, ts[i], ls[i])
		append(&list.list, tok)
		list.length += 1
	}
	return list, .OK
}

stmts :: proc(p: ^types.program_t) -> int {
	return p.length
}

stmt :: proc(p: ^types.program_t, i: int) -> ^types.syntax_t {
	return p.statements[i]
}

tt :: proc(s: ^types.syntax_t) -> types.token_type_t {
	return s.token.type
}

changes :: proc(t: ^testing.T, p: ^types.program_t, n: int) {
	testing.expectf(t, stmts(p) == n, "expected %d statements, got %d", n, stmts(p))
}

stmt_of :: proc(t: ^testing.T, ts: []types.token_type_t, ls: []string) -> (s: ^types.syntax_t, code: types.exit_codes) {
	tokens, _ := build_tokens(ts, ls)
	return statement(tokens, nil)
}

run_of :: proc(t: ^testing.T, ts: []types.token_type_t, ls: []string) -> (p: ^types.program_t, code: types.exit_codes) {
	tokens, _ := build_tokens(ts, ls)
	return run(tokens, nil)
}

@(test)
run_nil_tokens :: proc(t: ^testing.T) {
	prgm, code := run(nil, nil)
	testing.expectf(t, prgm == nil, "run(nil) should return nil program")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PARSE_RUN, "run(nil) wrong code: %v", code)
}

@(test)
branch_nil_tokens :: proc(t: ^testing.T) {
	prgm, code := branch(nil, nil)
	testing.expectf(t, prgm == nil, "branch(nil) should return nil program")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PARSER_BRANCH, "branch(nil) wrong code: %v", code)
}

@(test)
statement_nil_tokens :: proc(t: ^testing.T) {
	s, code := statement(nil, nil)
	testing.expectf(t, s == nil, "statement(nil) should return nil syntax")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PARSE_STATEMENT, "statement(nil) wrong code: %v", code)
}

@(test)
variable_declaration_nil_tokens :: proc(t: ^testing.T) {
	s, code := variable_declaration(nil)
	testing.expectf(t, s == nil, "variable_declaration(nil) should return nil syntax")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PARSE_VARIABLE_DECLARATION, "variable_declaration(nil) wrong code: %v", code)
}

@(test)
primary_expression_nil_tokens :: proc(t: ^testing.T) {
	s, code := primary_expression(nil)
	testing.expectf(t, s == nil, "primary_expression(nil) should return nil syntax")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PARSER_PRIMARY_EXPRESSION, "primary_expression(nil) wrong code: %v", code)
}

@(test)
expression_nil_tokens :: proc(t: ^testing.T) {
	s, code := expression(nil)
	testing.expectf(t, s == nil, "expression(nil) should return nil syntax")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_PARSER_PRIMARY_EXPRESSION, "expression(nil) wrong code: %v", code)
}

@(test)
branch_not_opened :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .TERMINATOR}, {"x", ";"})
	prgm, code := branch(tokens, nil)
	testing.expectf(t, prgm == nil, "branch should fail without left brace")
	testing.expectf(t, code == .BRACKET_NOT_OPENED_IN_PARSE_BRANCH, "branch wrong code: %v", code)
}

@(test)
branch_unexpected_eof_outer :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_BRACE, .END_OF_FILE}, {"{", "eof"})
	prgm, code := branch(tokens, nil)
	testing.expectf(t, prgm == nil, "branch should fail on eof")
	testing.expectf(t, code == .UNEXPECTED_EOF_IN_PARSE_BRANCH, "branch wrong code: %v", code)
}

@(test)
branch_unexpected_eof_inner :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_BRACE, .IDENTIFIER, .END_OF_FILE}, {"{", "x", "eof"})
	prgm, code := branch(tokens, nil)
	testing.expectf(t, prgm == nil, "branch should fail on inner eof")
	testing.expectf(t, code == .UNEXPECTED_EOF_IN_BRANCH_IN_PARSE_BRANCH, "branch wrong code: %v", code)
}

@(test)
branch_empty_body_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_BRACE, .RIGHT_BRACE, .TERMINATOR}, {"{", "}", ";"})
	prgm, code := branch(tokens, nil)
	testing.expectf(t, code == .OK, "branch failed: %v", code)
	testing.expectf(t, prgm != nil, "branch should return a program")
	changes(t, prgm, 0)
}

@(test)
branch_inner_statement_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_BRACE, .PRINT_LINE, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .RIGHT_BRACE, .TERMINATOR}, {"{", "println", "(", "5", ")", "}", ";"})
	prgm, code := branch(tokens, nil)
	testing.expectf(t, code == .OK, "branch failed: %v", code)
	testing.expectf(t, prgm != nil, "branch should return a program")
	changes(t, prgm, 1)
}

@(test)
parse_http_missing_dot :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.HTTP, .IDENTIFIER}, {"http", "x"})
	s, code := parse_http(tokens)
	testing.expectf(t, s == nil, "parse_http should fail without dot")
	testing.expectf(t, code == .EXPECTED_DOT_IN_PARSE_HTTP, "parse_http wrong code: %v", code)
}

@(test)
parse_http_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.HTTP, .DOT, .NUMBER}, {"http", ".", "5"})
	s, code := parse_http(tokens)
	testing.expectf(t, s == nil, "parse_http should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_HTTP, "parse_http wrong code: %v", code)
}

@(test)
parse_math_missing_dot :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.MATH, .IDENTIFIER}, {"math", "x"})
	s, code := parse_math(tokens)
	testing.expectf(t, s == nil, "parse_math should fail without dot")
	testing.expectf(t, code == .EXPECTED_DOT_IN_PARSE_MATH, "parse_math wrong code: %v", code)
}

@(test)
parse_math_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.MATH, .DOT, .NUMBER}, {"math", ".", "5"})
	s, code := parse_math(tokens)
	testing.expectf(t, s == nil, "parse_math should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_MATH, "parse_math wrong code: %v", code)
}

@(test)
parse_string_missing_dot :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.STRING, .IDENTIFIER}, {"string", "x"})
	s, code := parse_string(tokens)
	testing.expectf(t, s == nil, "parse_string should fail without dot")
	testing.expectf(t, code == .EXPECTED_DOT_IN_PARSE_STRING, "parse_string wrong code: %v", code)
}

@(test)
parse_string_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.STRING, .DOT, .NUMBER}, {"string", ".", "5"})
	s, code := parse_string(tokens)
	testing.expectf(t, s == nil, "parse_string should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_STRING, "parse_string wrong code: %v", code)
}

@(test)
parse_terminal_missing_dot :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.TERMINAL, .IDENTIFIER}, {"terminal", "x"})
	s, code := parse_terminal(tokens)
	testing.expectf(t, s == nil, "parse_terminal should fail without dot")
	testing.expectf(t, code == .EXPECTED_DOT_IN_PARSE_TERMINAL, "parse_terminal wrong code: %v", code)
}

@(test)
parse_time_missing_dot :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.TIME, .IDENTIFIER}, {"time", "x"})
	s, code := parse_time(tokens)
	testing.expectf(t, s == nil, "parse_time should fail without dot")
	testing.expectf(t, code == .EXPECTED_DOT_IN_PARSE_TIME, "parse_time wrong code: %v", code)
}

@(test)
parse_global_unexpected_keyword :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.GLOBAL, .NUMBER}, {"global", "5"})
	s, code := parse_global(tokens)
	testing.expectf(t, code == .UNEXPECTED_BEHAVIOUR_IN_PARSE_GLOBAL, "parse_global wrong code: %v", code)
}

@(test)
variable_declaration_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.VAR, .NUMBER}, {"var", "5"})
	s, code := variable_declaration(tokens)
	testing.expectf(t, s == nil, "variable_declaration should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_VARIABLE_DECLARATION, "variable_declaration wrong code: %v", code)
}

@(test)
variable_declaration_const_unassigned :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.CONST, .IDENTIFIER, .TERMINATOR}, {"const", "x", ";"})
	s, code := variable_declaration(tokens)
	testing.expectf(t, s == nil, "unassigned const should fail")
	testing.expectf(t, code == .UNASSIGNED_CONST_IN_VARIABLE_DECLARATION, "variable_declaration wrong code: %v", code)
}

@(test)
array_declaration_unclosed :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_BRACKET, .NUMBER, .END_OF_FILE}, {"[", "5", "eof"})
	s, code := array_declaration(tokens)
	testing.expectf(t, s == nil, "array_declaration should fail on unclosed bracket")
	testing.expectf(t, code == .BRACKET_NOT_CLOSED_NOT_CLOSED_IN_ARRAY_DECLARATION, "array_declaration wrong code: %v", code)
}

@(test)
parse_rm_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.RM, .NUMBER, .TERMINATOR}, {"rm", "5", ";"})
	s, code := parse_rm(tokens)
	testing.expectf(t, s == nil, "parse_rm should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_RM, "parse_rm wrong code: %v", code)
}

@(test)
variable_remove_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.REMOVE, .NUMBER, .TERMINATOR}, {"remove", "5", ";"})
	s, code := variable_remove(tokens)
	testing.expectf(t, s == nil, "variable_remove should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_VARIABLE_REMOVE, "variable_remove wrong code: %v", code)
}

@(test)
parse_if_missing_left_brace :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IF, .TRUE, .END_OF_FILE}, {"if", "true", "eof"})
	s, code := parse_if(tokens, nil)
	testing.expectf(t, s == nil, "parse_if should fail without left brace")
	testing.expectf(t, code == .EXPECTED_LEFT_BRACE_IN_PARSE_IF, "parse_if wrong code: %v", code)
}

@(test)
parse_function_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.FUNCTION, .NUMBER, .TERMINATOR}, {"function", "5", ";"})
	s, code := parse_function(tokens, nil)
	testing.expectf(t, s == nil, "parse_function should fail without identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_FUNCTION, "parse_function wrong code: %v", code)
}

@(test)
function_args_missing_left_paren :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .TERMINATOR}, {"x", ";"})
	args, code := function_args(tokens, nil)
	testing.expectf(t, args == nil, "function_args should fail without left paren")
	testing.expectf(t, code == .EXPECTED_LEFT_PAREN_IN_FUNCTION_ARGS, "function_args wrong code: %v", code)
}

@(test)
function_args_missing_identifier :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_PAREN, .VAR, .NUMBER, .RIGHT_PAREN}, {"(", "var", "5", ")"})
	args, code := function_args(tokens, nil)
	testing.expectf(t, args == nil, "function_args should fail on non-identifier param")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_FUNCTION_ARGS, "function_args wrong code: %v", code)
}

@(test)
function_args_missing_right_paren :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_PAREN, .TERMINATOR}, {"(", ";"})
	args, code := function_args(tokens, nil)
	testing.expectf(t, args == nil, "function_args should fail without right paren")
	testing.expectf(t, code == .EXPECTED_RIGHT_PAREN_IN_FUNCTION_ARGS, "function_args wrong code: %v", code)
}

@(test)
passed_function_args_unclosed :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.NUMBER, .END_OF_FILE}, {"5", "eof"})
	s, code := passed_function_args(tokens)
	testing.expectf(t, s == nil, "passed_function_args should fail on unclosed paren")
	testing.expectf(t, code == .UNCLOSED_PARENTHESIS_IN_PASSED_FUNCTION_ARGS, "passed_function_args wrong code: %v", code)
}

@(test)
parse_base_identifier_missing :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.NUMBER, .TERMINATOR}, {"5", ";"})
	s, tkn, code := parse_base_identifier(tokens)
	testing.expectf(t, s == nil, "parse_base_identifier should fail on non-identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_BASE_IDENTIFIER, "parse_base_identifier wrong code: %v", code)
}

@(test)
parse_base_identifier_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .TERMINATOR}, {"x", ";"})
	s, tkn, code := parse_base_identifier(tokens)
	testing.expectf(t, code == .OK, "parse_base_identifier failed: %v", code)
	testing.expectf(t, s != nil && tkn != nil, "parse_base_identifier should return syntax and token")
	testing.expectf(t, s.token.type == .IDENTIFIER, "expected identifier token")
}

@(test)
parse_member_access_wrong_next :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.DOT, .NUMBER}, {".", "5"})
	base, _ := syntax.create()
	s, tkn, code := parse_member_access(tokens, base)
	testing.expectf(t, s == nil, "parse_member_access should fail when next is not identifier")
	testing.expectf(t, code == .EXPECTED_IDENTIFIER_IN_PARSE_MEMBER_ACCESS, "parse_member_access wrong code: %v", code)
}

@(test)
parse_member_access_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.DOT, .IDENTIFIER, .TERMINATOR}, {".", "len", ";"})
	base, _ := syntax.create()
	s, tkn, code := parse_member_access(tokens, base)
	testing.expectf(t, code == .OK, "parse_member_access failed: %v", code)
	testing.expectf(t, s != nil && tkn != nil, "parse_member_access should return syntax and token")
	testing.expectf(t, s.token.type == .IDENTIFIER, "expected member identifier")
	testing.expectf(t, base.value == s, "member access should attach to base value")
}

@(test)
parse_len_adds_args :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LENGTH, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .TERMINATOR}, {"len", "(", "5", ")", ";"})
	s, code := parse_len(tokens)
	testing.expectf(t, code == .OK, "parse_len failed: %v", code)
	testing.expectf(t, s != nil, "parse_len should return syntax")
	testing.expectf(t, s.token.type == .LENGTH, "expected length token")
	testing.expectf(t, s.value != nil, "parse_len should capture args")
}

@(test)
parse_json_adds_args :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.JSON, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .TERMINATOR}, {"json", "(", "5", ")", ";"})
	s, code := parse_json(tokens)
	testing.expectf(t, code == .OK, "parse_json failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .JSON, "expected json token")
	testing.expectf(t, s.value != nil, "parse_json should capture args")
}

@(test)
parse_exists_adds_args :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.EXISTS, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .TERMINATOR}, {"exists", "(", "5", ")", ";"})
	s, code := parse_exists(tokens)
	testing.expectf(t, code == .OK, "parse_exists failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .EXISTS, "expected exists token")
	testing.expectf(t, s.value != nil, "parse_exists should capture args")
}

@(test)
parse_get_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .NUMBER, .TERMINATOR}, {"get", "5", ";"})
	s, code := parse_get(tokens)
	testing.expectf(t, code == .OK, "parse_get failed: %v", code)
	testing.expectf(t, s != nil, "parse_get should return syntax")
	testing.expectf(t, s.value != nil && s.value.token.type == .NUMBER, "parse_get should capture expression")
}

@(test)
parse_post_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .NUMBER, .TERMINATOR}, {"post", "5", ";"})
	s, code := parse_post(tokens)
	testing.expectf(t, code == .OK, "parse_post failed: %v", code)
	testing.expectf(t, s != nil, "parse_post should return syntax")
	testing.expectf(t, s.value != nil && s.value.token.type == .NUMBER, "parse_post should capture expression")
}

@(test)
parse_put_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .NUMBER, .TERMINATOR}, {"put", "5", ";"})
	s, code := parse_put(tokens)
	testing.expectf(t, code == .OK, "parse_put failed: %v", code)
	testing.expectf(t, s != nil, "parse_put should return syntax")
	testing.expectf(t, s.value != nil && s.value.token.type == .NUMBER, "parse_put should capture expression")
}

@(test)
parse_update_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .NUMBER, .TERMINATOR}, {"update", "5", ";"})
	s, code := parse_update(tokens)
	testing.expectf(t, code == .OK, "parse_update failed: %v", code)
	testing.expectf(t, s != nil, "parse_update should return syntax")
	testing.expectf(t, s.value != nil && s.value.token.type == .NUMBER, "parse_update should capture expression")
}

@(test)
function_args_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_PAREN, .VAR, .IDENTIFIER, .RIGHT_PAREN, .TERMINATOR}, {"(", "var", "a", ")", ";"})
	args, code := function_args(tokens, nil)
	testing.expectf(t, code == .OK, "function_args failed: %v", code)
	testing.expectf(t, args != nil && args.length == 1, "function_args should add one parameter")
}

@(test)
passed_function_args_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .TERMINATOR}, {"(", "5", ")", ";"})
	s, code := passed_function_args(tokens)
	testing.expectf(t, code == .OK, "passed_function_args failed: %v", code)
	testing.expectf(t, s != nil, "passed_function_args should return syntax")
	testing.expectf(t, s.branch != nil && s.branch.length == 1, "passed_function_args should capture one argument")
}

@(test)
parse_global_var_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.GLOBAL, .VAR, .IDENTIFIER, .TERMINATOR}, {"global", "var", "x", ";"})
	s, code := parse_global(tokens)
	testing.expectf(t, code == .OK, "parse_global failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .GLOBAL, "expected global token")
	testing.expectf(t, s.value != nil && s.value.token.type == .VAR, "global should wrap var declaration")
}

@(test)
primary_expression_number :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.NUMBER, .TERMINATOR}, {"5", ";"})
	s, code := primary_expression(tokens)
	testing.expectf(t, code == .OK, "primary_expression failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .NUMBER, "expected number literal")
}

@(test)
file_operation_right_arrow :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .RIGHT_ARROW, .IDENTIFIER, .TERMINATOR}, {"a", "->", "b", ";"})
	s, code := file_operation(tokens)
	testing.expectf(t, code == .OK, "file_operation failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .RIGHT_ARROW, "expected right-arrow node")
	testing.expectf(t, s.left != nil && s.left.token.type == .IDENTIFIER, "expected left operand")
	testing.expectf(t, s.right != nil && s.right.token.type == .IDENTIFIER, "expected right operand")
}

@(test)
string_operations_colon :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .COLON, .IDENTIFIER, .TERMINATOR}, {"a", ":", "b", ";"})
	s, code := string_operations(tokens)
	testing.expectf(t, code == .OK, "string_operations failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .COLON, "expected colon node")
	testing.expectf(t, s.left != nil && s.right != nil, "colon expects two operands")
}

@(test)
unary_bang :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.BANG, .IDENTIFIER, .TERMINATOR}, {"!", "x", ";"})
	s, code := unary(tokens)
	testing.expectf(t, code == .OK, "unary failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .BANG, "expected bang operator")
	testing.expectf(t, s.left != nil, "unary expects an operand")
}

@(test)
multiplicitive_star :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .STAR, .IDENTIFIER, .TERMINATOR}, {"a", "*", "b", ";"})
	s, code := multiplicitive(tokens)
	testing.expectf(t, code == .OK, "multiplicitive failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .STAR, "expected star node")
}

@(test)
additive_plus :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .PLUS, .IDENTIFIER, .TERMINATOR}, {"a", "+", "b", ";"})
	s, code := additive(tokens)
	testing.expectf(t, code == .OK, "additive failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .PLUS, "expected plus node")
}

@(test)
comparison_greater :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .GREATER, .IDENTIFIER, .TERMINATOR}, {"a", ">", "b", ";"})
	s, code := comparision(tokens)
	testing.expectf(t, code == .OK, "comparision failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .GREATER, "expected greater node")
}

@(test)
equality_equal :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .EQUAL_EQUAL, .IDENTIFIER, .TERMINATOR}, {"a", "==", "b", ";"})
	s, code := equality(tokens)
	testing.expectf(t, code == .OK, "equality failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .EQUAL_EQUAL, "expected equality node")
}

@(test)
and_or_and :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .AND, .IDENTIFIER, .TERMINATOR}, {"a", "and", "b", ";"})
	s, code := and_or(tokens)
	testing.expectf(t, code == .OK, "and_or failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .AND, "expected and node")
}

@(test)
assignment_equal :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .EQUAL, .IDENTIFIER, .TERMINATOR}, {"a", "=", "b", ";"})
	s, code := assignment(tokens)
	testing.expectf(t, code == .OK, "assignment failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .EQUAL, "expected assignment node")
	testing.expectf(t, s.right != nil, "assignment expects a right operand")
}

@(test)
parse_index_access_success :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.LEFT_BRACKET, .NUMBER, .RIGHT_BRACKET, .TERMINATOR}, {"[", "5", "]", ";"})
	base, _ := syntax.create()
	s, tkn, code := parse_index_access(tokens, base)
	testing.expectf(t, code == .OK, "parse_index_access failed: %v", code)
	testing.expectf(t, s != nil && tkn != nil, "parse_index_access should return syntax and token")
	testing.expectf(t, s.token.type == .NUMBER, "expected index expression")
	testing.expectf(t, base.value == s, "index access should attach to base value")
}

@(test)
parse_identifier_base :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .TERMINATOR, .TERMINATOR}, {"x", ";", ";"})
	s, code := parse_identifier(tokens)
	testing.expectf(t, code == .OK, "parse_identifier failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .IDENTIFIER, "expected identifier")
}

@(test)
parse_identifier_member :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .DOT, .IDENTIFIER, .TERMINATOR}, {"obj", ".", "len", ";"})
	s, code := parse_identifier(tokens)
	testing.expectf(t, code == .OK, "parse_identifier failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .IDENTIFIER, "expected base identifier")
	testing.expectf(t, s.value != nil && s.value.token.type == .IDENTIFIER, "member access should chain on value")
}

@(test)
parse_identifier_call :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .TERMINATOR}, {"f", "(", "5", ")", ";"})
	s, code := parse_identifier(tokens)
	testing.expectf(t, code == .OK, "parse_identifier failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .IDENTIFIER, "expected identifier")
	testing.expectf(t, s.left != nil, "function call should attach args on left")
}

@(test)
parse_while_components_sets_value :: proc(t: ^testing.T) {
	parent, _ := syntax.create()
	comp, _ := syntax.create()
	code := parse_while_components(parent, comp)
	testing.expectf(t, code == .OK, "parse_while_components failed: %v", code)
	testing.expectf(t, parent.value == comp, "while component should be stored on value")
}

@(test)
parse_for_components_sets_parts :: proc(t: ^testing.T) {
	parent, _ := syntax.create()
	c1, _ := syntax.create()
	c2, _ := syntax.create()
	c3, _ := syntax.create()
	code := parse_for_components(parent, c1, c2, c3)
	testing.expectf(t, code == .OK, "parse_for_components failed: %v", code)
	testing.expectf(t, parent.left == c1 && parent.value == c2 && parent.right == c3, "for components misplaced")
}

@(test)
line_parses_single_expression :: proc(t: ^testing.T) {
	tokens, _ := build_tokens({.IDENTIFIER, .TERMINATOR, .TERMINATOR, .NUMBER}, {"x", ";", ";", "5"})
	s, code := line(tokens, nil)
	testing.expectf(t, code == .OK, "line failed: %v", code)
	testing.expectf(t, s != nil && s.token.type == .IDENTIFIER, "line should parse expression")
}

@(test)
integration_empty_program :: proc(t: ^testing.T) {
	p, code := run_of(t, {.END_OF_FILE}, {"eof"})
	testing.expectf(t, code == .OK, "parse empty failed: %v", code)
	changes(t, p, 0)
}

@(test)
integration_var_declaration :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.VAR, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"var", "x", "=", "5", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .VAR, "expected var keyword, got %v", tt(s))
	testing.expectf(t, s.left != nil && s.left.token.type == .IDENTIFIER, "expected variable name")
	testing.expectf(t, s.left.token.literal == "x", "wrong variable name: %q", s.left.token.literal)
	testing.expectf(t, s.left.value != nil && s.left.value.token.type == .NUMBER, "expected initializer")
}

@(test)
integration_var_chain :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.VAR, .IDENTIFIER, .COMMA, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"var", "a", ",", "b", "=", "2", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .VAR, "expected var keyword")
	testing.expectf(t, s.left != nil && s.left.left != nil, "expected chained variable declarations")
	testing.expectf(t, s.left.token.literal == "a", "first var should be a")
	testing.expectf(t, s.left.left.token.literal == "b", "second var should be b")
}

@(test)
integration_const_unassigned_errors :: proc(t: ^testing.T) {
	_, code := stmt_of(t, {.CONST, .IDENTIFIER, .TERMINATOR, .END_OF_FILE}, {"const", "c", ";", "eof"})
	testing.expectf(t, code == .UNASSIGNED_CONST_IN_VARIABLE_DECLARATION, "unassigned const wrong code: %v", code)
}

@(test)
integration_assignment :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"x", "=", "5", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .EQUAL, "expected assignment node")
}

@(test)
integration_arithmetic_precedence :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.IDENTIFIER, .EQUAL, .NUMBER, .PLUS, .NUMBER, .STAR, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"y", "=", "1", "+", "2", "*", "3", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	eq := s
	plus := eq.right
	mul := plus.right
	testing.expectf(t, tt(eq) == .EQUAL, "expected assignment at top")
	testing.expectf(t, plus != nil && tt(plus) == .PLUS, "expected plus as right of assignment")
	testing.expectf(t, mul != nil && tt(mul) == .STAR, "expected star as right of plus")
	testing.expectf(t, mul.left != nil && mul.left.token.literal == "2", "star left should be 2")
	testing.expectf(t, mul.right != nil && mul.right.token.literal == "3", "star right should be 3")
	testing.expectf(t, plus.left != nil && plus.left.token.literal == "1", "plus left should be 1")
}

@(test)
integration_if :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.IF, .IDENTIFIER, .LEFT_BRACE, .IDENTIFIER, .EQUAL, .NUMBER, .RIGHT_BRACE, .TERMINATOR, .END_OF_FILE}, {"if", "x", "{", "y", "=", "1", "}", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .IF, "expected if keyword")
	testing.expectf(t, s.value != nil, "if needs a condition")
	testing.expectf(t, s.branch != nil && s.branch.type == .IF, "if branch should be typed IF")
	changes(t, s.branch, 1)
}

@(test)
integration_if_else :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.IF, .IDENTIFIER, .LEFT_BRACE, .RIGHT_BRACE, .ELSE, .LEFT_BRACE, .RIGHT_BRACE, .TERMINATOR, .END_OF_FILE}, {"if", "x", "{", "}", "else", "{", "}", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .IF, "expected if keyword")
	testing.expectf(t, s.right != nil, "if should chain an else")
	testing.expectf(t, s.right.token.type == .ELSE, "expected else token")
	testing.expectf(t, s.right.branch != nil && s.right.branch.type == .IF, "else branch should be typed IF")
}

@(test)
integration_if_elseif :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.IF, .IDENTIFIER, .LEFT_BRACE, .RIGHT_BRACE, .ELSE_IF, .IDENTIFIER, .LEFT_BRACE, .RIGHT_BRACE, .TERMINATOR, .END_OF_FILE}, {"if", "x", "{", "}", "elif", "y", "{", "}", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .IF, "expected if keyword")
	testing.expectf(t, s.right != nil && s.right.token.type == .ELSE_IF, "expected else-if chain")
	testing.expectf(t, s.right.branch != nil && s.right.branch.type == .IF, "else-if branch should be typed IF")
}

@(test)
integration_for_loop :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.FOR, .LEFT_PAREN, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .IDENTIFIER, .LESS, .NUMBER, .TERMINATOR, .IDENTIFIER, .PLUS_EQUAL, .NUMBER, .RIGHT_PAREN, .LEFT_BRACE, .RIGHT_BRACE, .TERMINATOR, .END_OF_FILE}, {"for", "(", "i", "=", "0", ";", "i", "<", "5", ";", "i", "+=", "1", ")", "{", "}", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .FOR, "expected for keyword")
	testing.expectf(t, s.left != nil && s.value != nil && s.right != nil, "for needs three components")
	testing.expectf(t, s.branch != nil && s.branch.type == .LOOP, "for branch should be typed LOOP")
}

@(test)
integration_while_loop :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.FOR, .LEFT_PAREN, .IDENTIFIER, .RIGHT_PAREN, .LEFT_BRACE, .RIGHT_BRACE, .TERMINATOR, .END_OF_FILE}, {"for", "(", "x", ")", "{", "}", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .FOR, "expected for keyword")
	testing.expectf(t, s.value != nil, "while form should capture condition")
	testing.expectf(t, s.branch != nil && s.branch.type == .LOOP, "while branch should be typed LOOP")
}

@(test)
integration_function :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.FUNCTION, .IDENTIFIER, .LEFT_PAREN, .VAR, .IDENTIFIER, .RIGHT_PAREN, .LEFT_BRACE, .RETURN, .IDENTIFIER, .RIGHT_BRACE, .TERMINATOR, .END_OF_FILE}, {"function", "f", "(", "var", "a", ")", "{", "return", "a", "}", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .FUNCTION, "expected function keyword")
	testing.expectf(t, s.right != nil && s.right.token.type == .IDENTIFIER, "expected function name")
	testing.expectf(t, s.right.token.literal == "f", "wrong function name")
	testing.expectf(t, s.right.args != nil, "function should capture args")
	testing.expectf(t, s.right.branch != nil && s.right.branch.type == .FUNCTION, "function branch should be typed FUNCTION")
}

@(test)
integration_function_inline_body :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.FUNCTION, .IDENTIFIER, .LEFT_PAREN, .RIGHT_PAREN, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .TERMINATOR, .END_OF_FILE}, {"function", "g", "(", ")", "x", "=", "1", ";", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .FUNCTION, "expected function keyword")
	testing.expectf(t, s.right != nil && s.right.branch != nil && s.right.branch.type == .FUNCTION, "inline function body should be typed FUNCTION")
}

@(test)
integration_print :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.PRINT, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"print", "(", "hi", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .PRINT, "expected print keyword")
	testing.expectf(t, s.value != nil && s.value.branch != nil, "print should capture arguments")
}

@(test)
integration_println :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.PRINT_LINE, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"println", "(", "hi", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .PRINT_LINE, "expected println keyword")
	testing.expectf(t, s.value != nil, "println should capture arguments")
}

@(test)
integration_return :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.RETURN, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"return", "5", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .RETURN, "expected return keyword")
	testing.expectf(t, s.value != nil && s.value.token.type == .NUMBER, "return should capture value")
}

@(test)
integration_break_continue :: proc(t: ^testing.T) {
	bs, code := stmt_of(t, {.BREAK, .TERMINATOR, .END_OF_FILE}, {"break", ";", "eof"})
	cs, code2 := stmt_of(t, {.CONTINUE, .TERMINATOR, .END_OF_FILE}, {"continue", ";", "eof"})
	testing.expectf(t, code == .OK && code2 == .OK, "parse failed: %v %v", code, code2)
	testing.expectf(t, tt(bs) == .BREAK, "expected break keyword")
	testing.expectf(t, tt(cs) == .CONTINUE, "expected continue keyword")
}

@(test)
integration_clear_sleep_error :: proc(t: ^testing.T) {
	clr, c1 := stmt_of(t, {.CLEAR, .TERMINATOR, .END_OF_FILE}, {"clear", ";", "eof"})
	slp, c2 := stmt_of(t, {.SLEEP, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"sleep", "1", ";", "eof"})
	err, c3 := stmt_of(t, {.ERROR, .STRING_WRAPPER, .TERMINATOR, .END_OF_FILE}, {"error", "oops", ";", "eof"})
	testing.expectf(t, c1 == .OK && c2 == .OK && c3 == .OK, "parse failed: %v %v %v", c1, c2, c3)
	testing.expectf(t, tt(clr) == .CLEAR, "expected clear keyword")
	testing.expectf(t, tt(slp) == .SLEEP, "expected sleep keyword")
	testing.expectf(t, tt(err) == .ERROR, "expected error keyword")
}

@(test)
integration_out :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.OUT, .STRING_WRAPPER, .TERMINATOR, .END_OF_FILE}, {"out", "x", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .OUT, "expected out keyword")
	testing.expectf(t, s.value != nil, "out should capture value")
}

@(test)
integration_rm :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.RM, .IDENTIFIER, .COMMA, .IDENTIFIER, .TERMINATOR, .END_OF_FILE}, {"rm", "a", ",", "b", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .RM, "expected rm keyword")
	testing.expectf(t, s.left != nil, "rm should capture identifiers")
}

@(test)
integration_remove :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.REMOVE, .IDENTIFIER, .COMMA, .IDENTIFIER, .TERMINATOR, .END_OF_FILE}, {"remove", "a", ",", "b", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .REMOVE, "expected remove keyword")
	testing.expectf(t, s.left != nil, "remove should capture identifiers")
}

@(test)
integration_array_declaration :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.LEFT_BRACKET, .NUMBER, .COMMA, .NUMBER, .COMMA, .NUMBER, .RIGHT_BRACKET, .TERMINATOR, .END_OF_FILE}, {"[", "1", ",", "2", ",", "3", "]", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .LEFT_BRACKET, "expected array literal")
	testing.expectf(t, s.left != nil && s.left.token.type == .NUMBER, "expected first element")
	testing.expectf(t, s.left.right != nil, "expected chained elements")
}

@(test)
integration_http :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.HTTP, .DOT, .IDENTIFIER, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"http", ".", "get", "(", "url", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .HTTP, "expected http keyword")
	testing.expectf(t, s.value != nil && s.value.token.type == .IDENTIFIER, "expected http method")
	testing.expectf(t, s.value.value != nil, "http should capture args")
}

@(test)
integration_math :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.MATH, .DOT, .IDENTIFIER, .LEFT_PAREN, .NUMBER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"math", ".", "round", "(", "1.5", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .MATH, "expected math keyword")
	testing.expectf(t, s.value != nil && s.value.token.literal == "round", "expected math method")
	testing.expectf(t, s.value.value != nil, "math method should capture args")
}

@(test)
integration_string_method :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.STRING, .DOT, .IDENTIFIER, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"string", ".", "len", "(", "hi", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .STRING, "expected string keyword")
	testing.expectf(t, s.value != nil && s.value.token.literal == "len", "expected string method")
	testing.expectf(t, s.value.value != nil, "string method should capture args")
}

@(test)
integration_time :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.TIME, .DOT, .IDENTIFIER, .LEFT_PAREN, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"time", ".", "now", "(", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .TIME, "expected time keyword")
	testing.expectf(t, s.value != nil && s.value.token.literal == "now", "expected time method")
}

@(test)
integration_terminal :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.TERMINAL, .DOT, .IDENTIFIER, .TERMINATOR, .END_OF_FILE}, {"terminal", ".", "text", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .TERMINAL, "expected terminal keyword")
	testing.expectf(t, s.value != nil, "expected terminal member")
}

@(test)
integration_json_exists_len :: proc(t: ^testing.T) {
	js, c1 := stmt_of(t, {.JSON, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"json", "(", "{", ")", ";", "eof"})
	ex, c2 := stmt_of(t, {.EXISTS, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"exists", "(", "x", ")", ";", "eof"})
	ln, c3 := stmt_of(t, {.LENGTH, .LEFT_PAREN, .STRING_WRAPPER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"len", "(", "abc", ")", ";", "eof"})
	testing.expectf(t, c1 == .OK && c2 == .OK && c3 == .OK, "parse failed: %v %v %v", c1, c2, c3)
	testing.expectf(t, tt(js) == .JSON, "expected json keyword")
	testing.expectf(t, tt(ex) == .EXISTS, "expected exists keyword")
	testing.expectf(t, tt(ln) == .LENGTH, "expected len keyword")
}

@(test)
integration_key_in_execute :: proc(t: ^testing.T) {
	ky, c1 := stmt_of(t, {.KEY, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"key", "5", ";", "eof"})
	inn, c2 := stmt_of(t, {.IN, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"in", "5", ";", "eof"})
	ex, c3 := stmt_of(t, {.EXECUTE, .STRING_WRAPPER, .TERMINATOR, .END_OF_FILE}, {"execute", "x", ";", "eof"})
	testing.expectf(t, c1 == .OK && c2 == .OK && c3 == .OK, "parse failed: %v %v %v", c1, c2, c3)
	testing.expectf(t, tt(ky) == .KEY, "expected key keyword")
	testing.expectf(t, tt(inn) == .IN, "expected in keyword")
	testing.expectf(t, tt(ex) == .EXECUTE, "expected execute keyword")
}

@(test)
integration_global_var :: proc(t: ^testing.T) {
	s, code := stmt_of(t, {.GLOBAL, .VAR, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .END_OF_FILE}, {"global", "var", "x", "=", "1", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	testing.expectf(t, tt(s) == .GLOBAL, "expected global keyword")
	testing.expectf(t, s.value != nil && s.value.token.type == .VAR, "global should wrap var")
}

@(test)
integration_run_joins_statements :: proc(t: ^testing.T) {
	p, code := run_of(t, {.VAR, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .VAR, .IDENTIFIER, .EQUAL, .NUMBER, .TERMINATOR, .PRINT_LINE, .LEFT_PAREN, .IDENTIFIER, .PLUS, .IDENTIFIER, .RIGHT_PAREN, .TERMINATOR, .END_OF_FILE}, {"var", "a", "=", "1", ";", "var", "b", "=", "2", ";", "println", "(", "a", "+", "b", ")", ";", "eof"})
	testing.expectf(t, code == .OK, "parse failed: %v", code)
	changes(t, p, 3)
	testing.expectf(t, tt(stmt(p, 0)) == .VAR, "first statement should be var")
	testing.expectf(t, tt(stmt(p, 1)) == .VAR, "second statement should be var")
	testing.expectf(t, tt(stmt(p, 2)) == .PRINT_LINE, "third statement should be println")
}
