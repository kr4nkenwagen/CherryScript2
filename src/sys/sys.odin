package sys

import "../types"
import "core:fmt"
import "core:strings"

CLR_RESET :: "\e[0m"
CLR_BOLD :: "\e[1m"
CLR_BORDER :: "\e[38;5;238m" // Dark gray border
CLR_TITLE :: "\e[38;5;204m" // Cherry Pink
CLR_CYAN :: "\e[38;5;75m" // Muted Cyan
CLR_AMBER :: "\e[38;5;215m" // Soft Amber
CLR_GREEN :: "\e[38;5;114m" // Pastel Green
CLR_TEXT :: "\e[38;5;252m" // Crisp Off-White
CLR_MUTED :: "\e[38;5;243m" // Subdued Gray
CLR_ERR :: "\e[31m" //
CLR_CONST :: "\e[38;5;220m" // Gold for Const
CLR_TOKEN_HL :: "\e[7;1m" // Inverse + Bold for Token Highlight


g_has_errored := false

is_error :: proc(exit_code: types.exit_codes, loc := #caller_location) -> (err: bool) {
	if exit_code == types.exit_codes.OK do return
	err = true
	if g_has_errored do return true
	g_has_errored = true
	return
}

print_error :: proc(
	error_code: types.exit_codes,
	token: ^types.token_t,
	src: ^types.source_code_t,
) {
	if token == nil {
		fmt.printf(
			"%s%s[ERR] %s %s\n",
			CLR_RESET,
			CLR_ERR,
			CLR_RESET,
			parse_error(error_code, token),
		)
		return
	}
	file := get_correct_source_file(token.line, src)
	split_src := strings.split(src.content, "\n", context.allocator)
	raw_line := token.line - 1
	src_start := raw_line - 3 > 0 ? raw_line - 3 : 0
	if file.imported_at_index != 0 && src_start < file.imported_at_index do src_start = file.imported_at_index - 1
	marker_length := len(token.literal)
	if marker_length < 0 do marker_length = 0
	column := token.column - 1
	if column < 0 do column = 0
	literal_marker := strings.repeat("^", marker_length)
	literal_marker_distance := strings.repeat(" ", column)
	fmt.printf(
		"%s%s[ERR]%s In [%s%s%s] %s%d%s:%s%d\n%s",
		CLR_ERR,
		CLR_BOLD,
		CLR_RESET,
		CLR_TEXT,
		file.name,
		CLR_RESET,
		CLR_TEXT,
		(file.imported_at_index == 0 ? token.line : token.line - file.imported_at_index + 1),
		CLR_MUTED,
		CLR_TEXT,
		token.column,
		CLR_RESET,
	)
	for i := src_start; i <= raw_line; i += 1 {
		fmt.printf(
			"%3d%s|%s %s\n",
			i + 1 - (file.imported_at_index - 1),
			CLR_MUTED,
			CLR_RESET,
			paint_code(split_src[i]),
		)
	}
	fmt.printf(
		"   %s|%s %s%s%s%s %s%s\n",
		CLR_MUTED,
		CLR_RESET,
		literal_marker_distance,
		CLR_ERR,
		literal_marker,
		CLR_TEXT,
		CLR_BOLD,
		parse_error(error_code, token),
	)
}


get_correct_source_file :: proc(
	line: int,
	src: ^types.source_code_t,
) -> (
	src_file: types.source_file_t,
) {
	if len(src.included_sources) > 0 {
		src_file = src.included_sources[0]
		for i := 1; i < len(src.included_sources); i += 1 {
			if line < src.included_sources[i].imported_at_index ||
			   i == len(src.included_sources) - 1 {
				exit_point :=
					src.included_sources[i].imported_at_index + src.included_sources[i].length
				if line < exit_point do i -= 1
				for line >= exit_point && i > 0 {
					i -= 1
					exit_point += src.included_sources[i].length
				}
				src_file = src.included_sources[i]
				return
			}
		}
	}
	return {name = "REPL", imported_at_index = 0}
}
