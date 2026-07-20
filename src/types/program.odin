package types

program_type_t :: enum {
	SOURCE,
	LOOP,
	FUNCTION,
	IF,
}

program_t :: struct {
	exit:        bool,
	breaking:    bool,
	continueing: bool,
	pointer:     int,
	type:        program_type_t,
	length:      int,
	parent:      ^program_t,
	statements:  [dynamic]^syntax_t,
	ret_value:   ^object_t,
}
