package types

source_code_t :: struct {
	is_at_end: bool,
	length:    int,
	pointer:   int,
	line:      int,
	column:    int,
	content:   string,
	location:  string,
}
