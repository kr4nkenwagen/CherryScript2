package types

object_type_t :: enum {
	INT,
	FLOAT,
	STRING,
	ARRAY,
	NULL,
	BOOL,
	FUNCTION,
	FILE,
	JSON,
}

object_data_t :: union {
	int,
	f32,
	string,
	bool,
	rawptr,
	object_array_t,
	object_file_t,
	object_json_t,
}

object_t :: struct {
	is_marked: bool,
	is_const:  bool,
	type:      object_type_t,
	name:      string,
	data:      object_data_t,
	parent:    ^object_t,
}

object_array_t :: struct {
	count: int,
	value: [dynamic]^object_t,
}

object_file_t :: struct {
	name: string,
}

object_json_t :: struct {
	value: [dynamic]^object_t,
	file:  object_file_t,
}
