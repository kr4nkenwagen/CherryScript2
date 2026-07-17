package types

stack_t :: struct {
	count:             int,
	parent_references: int,
	capacity:          int,
	data:              [dynamic]^object_t,
}
