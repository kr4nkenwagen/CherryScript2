package types
debug_type_t :: enum {
	NONE,
	TOKENS,
	AST,
	EVAL,
}
arguments_t :: struct {
	debug_level:  debug_type_t,
	source_files: [dynamic]string,
	script_args:  [dynamic]string,
	pipe:         [dynamic]string,
}
