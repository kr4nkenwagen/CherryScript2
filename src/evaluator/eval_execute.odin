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
	stdout, stderr, exitcode := execute_command(val.data.(string)) or_return
	ret_obj = object.create_json("{}") or_return
	ret_obj_ref := &ret_obj.data.(types.object_json_t)
	std_out := object.create_string(strings.clone(string(stdout))) or_return
	std_out.name = "stdout"
	append(&ret_obj_ref.value, std_out)
	std_err := object.create_string(strings.clone(string(stderr))) or_return
	std_err.name = "stderr"
	append(&ret_obj_ref.value, std_err)
	exit_code := object.create_int(exitcode) or_return
	exit_code.name = "exit_code"
	append(&ret_obj_ref.value, exit_code)
	return
}


execute_command :: proc(
	str: string,
) -> (
	ret_stdout, ret_stderr: string,
	ret_exit_code: int,
	code: types.exit_codes,
) {
	fields := strings.fields(str)
	if len(fields) == 0 do return {}, {}, 0, .FAILED_TO_EXECUTE_SYSTEM_COMMAND
	desc := os.Process_Desc {
		command = fields,
	}
	state, stdout, stderr, err := os.process_exec(desc, context.allocator)
	if err != nil {
		return {}, {}, 0, .FAILED_TO_EXECUTE_SYSTEM_COMMAND
	}
	defer delete(stdout, context.allocator)
	defer delete(stderr, context.allocator)
	ret_stdout = strings.clone(string(stdout))
	ret_stderr = strings.clone(string(stderr))
	if ret_stdout == {} do ret_stdout = ""
	if ret_stderr == {} do ret_stderr = ""
	ret_exit_code = state.exit_code


	return
}
