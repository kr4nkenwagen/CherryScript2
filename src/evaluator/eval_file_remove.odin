
package evaluator

import "../stack"
import "../sys"
import "../types"
import "../vm"
import "core:os"

eval_file_remove :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prog: ^types.program_t,
) -> types.exit_codes {
	if synt == nil {
		return .OBJECT_IS_NIL
	}
	curr := synt.left
	for curr != nil && curr.token.type == .IDENTIFIER {
		curr_stack, curr_stack_err := vm.current_frame(stck)
		if sys.is_error(curr_stack_err) {
			return curr_stack_err
		}
		obj, obj_err := stack.get(curr_stack, curr.token.literal)
		if sys.is_error(obj_err) {
			return obj_err
		}
		if obj != nil {
			os.remove(obj.data.(types.object_file_t).name)
		}
		curr = curr.left
	}
	return .OK
}
