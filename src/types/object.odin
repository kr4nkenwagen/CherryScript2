package types

object_type_t :: enum {
	INT,
	FLOAT,
	STRING,
	ARRAY,
	VECTOR,
	NULL,
	BOOL,
	FUNCTION,
}

object_data_t :: union {
	int,
	f32,
	string,
	bool,
	object_array_t,
	object_vector_t,
}

object_t :: struct {
	is_marked: bool,
	is_const:  bool,
	ref_count: int,
	type:      object_type_t,
	name:      string,
	data:      object_data_t,
}

object_array_t :: struct {
	count: int,
	value: [dynamic]object_t,
}

object_vector_t :: struct {
	x: ^object_t,
	y: ^object_t,
	z: ^object_t,
}
