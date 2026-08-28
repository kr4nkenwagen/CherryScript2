package evaluator

import "../object"
import "../stack"
import "../types"
import "../vm"

run :: proc(
	prog: ^types.program_t,
	stck: ^types.vm_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if prog == nil do return nil, .OBJECT_IS_NIL_IN_EVAL_RUN
	prog.pointer = 0
	prog.exit = false

	for prog.pointer < prog.length && !prog.exit {
		if prog.exit do break
		if prog.continueing {
			prog.pointer = prog.length
			prog.continueing = false
			continue
		}
		obj = eval_primary_expression(prog.statements[prog.pointer], stck, prog) or_return
		prog.pointer += 1
	}
	if prog.exit do return prog.ret_value, .OK
	return
}

branch_with_no_args :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	new_stack := stack.create() or_return
	vm.push_frame(stck, new_stack, true) or_return
	defer vm.pop_frame(stck)
	value_data := run(synt.branch, stck) or_return
	if value_data == nil do return nil, .OK
	obj = object.copy(value_data) or_return
	return
}

branch_with_args :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	new_stack := stack.create() or_return
	vm_prev := vm.current_frame(stck) or_return
	arg_vals: [dynamic]^types.object_t
	defer delete(arg_vals)
	for &i in synt.value.branch.statements {
		arg_val := eval_primary_expression(i, stck, prgm) or_return
		append(&arg_vals, arg_val)
	}
	fn_obj := stack.get(vm_prev, synt.token.literal) or_return
	vm.push_frame(stck, new_stack, false) or_return
	defer vm.pop_frame(stck)
	run(synt.args, stck) or_return
	curr_stack := vm.current_frame(stck) or_return
	if curr_stack.count - curr_stack.parent_references != synt.value.branch.length do return nil, .INCORRECT_NUMBER_OF_REFERENCES_IN_EVAL_BRANCH
	for i := curr_stack.parent_references; i < curr_stack.count; i += 1 {
		idx := i - curr_stack.parent_references
		curr_stack.data[i].data = arg_vals[idx].data
		curr_stack.data[i].type = arg_vals[idx].type
	}
	if fn_obj != nil && fn_obj.type == .FUNCTION {
		fn_copy := object.copy(fn_obj) or_return
		stack.push(curr_stack, fn_copy)
	}
	value_data := run(synt.branch, stck) or_return
	if value_data == nil do return nil, .OK
	obj = object.copy(value_data) or_return
	return
}

branch :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
	prgm: ^types.program_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL_IN_EVAL_BRANCH
	}
	if synt.args == nil {
		obj, code = branch_with_no_args(synt, stck, prgm)
	} else {
		obj, code = branch_with_args(synt, stck, prgm)
	}
	return
}
