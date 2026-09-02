package types

source_code_t :: struct {
	is_at_end:        bool,
	length:           int,
	pointer:          int,
	line:             int,
	column:           int,
	content:          string,
	location:         string,
	included_sources: [dynamic]source_file_t,
}


source_file_t :: struct {
	name:              string,
	length:            int,
	imported_at_index: int,
}
