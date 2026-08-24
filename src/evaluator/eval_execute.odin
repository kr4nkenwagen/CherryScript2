package evaluator

import "../object"
import "../types"
import "core:os"
import "core:strings"

eval_execute :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
) -> (
	ret_obj: ^types.object_t,
	code: types.exit_codes,
) {
	val := eval_primary_expression(synt.value, stck, prgm) or_return
	if val.type != .STRING do return nil, .VALUE_IS_NOT_STRING_IN_EVAL_EXECUTE
	str := execute_command(val.data.(string)) or_return
	ret_obj = object.create_string(str) or_return
	return
}


execute_command :: proc(str: string) -> (ret_str: string, code: types.exit_codes) {
	fields := strings.fields(str)
	if len(fields) == 0 do return {}, .FAILED_TO_EXECUTE_SYSTEM_COMMAND
	desc := os.Process_Desc {
		command = fields,
	}
	state, stdout, stderr, err := os.process_exec(desc, context.allocator)
	if err != nil {
		return {}, .FAILED_TO_EXECUTE_SYSTEM_COMMAND
	}
	defer delete(stdout, context.allocator)
	defer delete(stderr, context.allocator)
	ret_str = strings.clone(string(stdout))
	return
}
