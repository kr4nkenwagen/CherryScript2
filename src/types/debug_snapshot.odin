package types

debug_snapshot_collection_t :: struct {
	snapshots: [dynamic]^debug_snapshot_t,
}

debug_snapshot_t :: struct {
	syntax: ^token_t,
	output: [dynamic]^string,
	stack:  [dynamic]^object_t,
}
