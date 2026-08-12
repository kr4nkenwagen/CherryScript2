package types

vm_t :: struct {
	count:          int,
	global_objects: ^stack_t,
	frames:         [dynamic]^stack_t,
	references:     stack_t,
}
