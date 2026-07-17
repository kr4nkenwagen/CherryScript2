package types

vm_t :: struct {
	count:      int,
	objects:    ^stack_t,
	frames:     [dynamic]^stack_t,
	references: stack_t,
}
