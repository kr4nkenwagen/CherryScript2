package types

source_code_t :: struct {
	content:   string,
	length:    int,
	is_at_end: bool,
	pointer:   int,
	line:      int,
	column:    int,
}
