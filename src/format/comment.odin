package format

comment_t :: struct {
	text:   string,
	line:   int,
	column: int,
}

capture_comments :: proc(content: string) -> [dynamic]comment_t {
	comments: [dynamic]comment_t
	line := 1
	column := 1
	i := 0
	for i < len(content) {
		c := content[i]
		switch c {
		case '\n':
			line += 1
			column = 1
			i += 1
		case '"', '\'':
			i, column = skip_quoted(content, i, column, rune(c))
		case '#':
			start := i
			com_line := line
			com_column := column
			i += 1
			column += 1
			for i < len(content) && content[i] != '\n' && content[i] != '#' {
				i += 1
				column += 1
			}
			append(
				&comments,
				comment_t{text = content[start:i], line = com_line, column = com_column},
			)
		case:
			i += 1
			column += 1
		}
	}
	return comments
}

skip_quoted :: proc(content: string, i: int, column: int, quote: rune) -> (int, int) {
	j := i + 1
	col := column + 1
	for j < len(content) {
		switch content[j] {
		case '\\':
			j += 2
		case u8(quote):
			return j + 1, col + 1
		case '\n':
			return j, col
		case:
			j += 1
			col += 1
		}
	}
	return j, col
}

