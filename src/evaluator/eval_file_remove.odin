package evaluator

import "../stack"
import "../types"
import "../vm"
import "core:os"

eval_file_remove :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> (
	code: types.exit_codes,
) {
	if synt == nil do return .OBJECT_IS_NIL_IN_EVAL_FILE_REMOVE
	prog.stats.current_syntax = synt
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack := vm.current_frame(stck) or_return
		obj := stack.get(curr_stack, curr.token.literal) or_return
		if obj != nil {
			#partial switch (obj.type) {
			case .FILE:
				os.remove(obj.data.(types.object_file_t).name)
			case .JSON:
				os.remove(obj.data.(types.object_json_t).file.name)
			case:
				return .UNEXPECTED_OBJECT_TYPE_IN_EVAL_FILE_REMOVAL
			}
		}
		curr = curr.left
	}
	return
}
