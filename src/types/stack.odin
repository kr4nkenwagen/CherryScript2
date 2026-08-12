package types

stack_t :: struct {
	count:             int,
	parent_references: int,
	capacity:          int,
	global_data:       ^stack_t,
	data:              [dynamic]^object_t,
}
