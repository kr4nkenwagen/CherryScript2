package evaluator

import "../object"
import "../stack"
import "../types"
import "../vm"
import "core:time"

g_debug: bool
g_start_time_execution: ^time.Tick

run :: proc(
	prog: ^types.program_t,
	stck: ^types.vm_t,
	debug_mode: bool,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if prog == nil do return nil, types.exit_codes.OBJECT_IS_NIL
	g_debug = debug_mode
	prog.pointer = 0
	prog.exit = false
	value: ^types.object_t
	if g_start_time_execution == nil {
		g_start_time_execution = new(time.Tick)
		g_start_time_execution^ = time.tick_now()
	}
	for prog.pointer < prog.length && !prog.exit {
		if prog.exit do break
		if prog.continueing {
			prog.pointer = prog.length
			prog.continueing = false
			continue
		}
		value_err: types.exit_codes
		value = eval_primary_expression(prog.statements[prog.pointer], stck, prog) or_return
		prog.pointer += 1
	}
	if prog.exit do return prog.ret_value, .OK
	return value, .OK
}

branch :: proc(
	synt: ^types.syntax_t,
	stck: ^types.vm_t,
) -> (
	obj: ^types.object_t,
	code: types.exit_codes,
) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL
	}
	// -------------------------------------------------------------
	// Path 1: synt.args == nil
	// -------------------------------------------------------------
	if synt.args == nil {
		new_stack := stack.create() or_return
		vm.push_frame(stck, new_stack, true) or_return
		defer vm.pop_frame(stck)
		value_data := run(synt.branch, stck, g_debug) or_return
		if value_data == nil do return nil, .OK
		value := object.copy(value_data) or_return
		return value, .OK
	}
	// -------------------------------------------------------------
	// Path 2: synt.args != nil
	// -------------------------------------------------------------
	new_stack := stack.create() or_return
	vm_prev := vm.current_frame(stck) or_return
	arg_vals: [dynamic]^types.object_t
	defer delete(arg_vals)
	for &i in synt.value.branch.statements {
		arg_val := eval_primary_expression(i, stck, nil) or_return
		append(&arg_vals, arg_val)
	}
	fn_obj := stack.get(vm_prev, synt.token.literal) or_return
	vm.push_frame(stck, new_stack, false) or_return
	defer vm.pop_frame(stck)
	run(synt.args, stck, g_debug) or_return
	curr_stack := vm.current_frame(stck) or_return
	if curr_stack.count - curr_stack.parent_references != synt.value.branch.length do return nil, .INCORRECT_NUMBER_OF_REFERENCES
	for i := curr_stack.parent_references; i < curr_stack.count; i += 1 {
		idx := i - curr_stack.parent_references
		curr_stack.data[i].data = arg_vals[idx].data
		curr_stack.data[i].type = arg_vals[idx].type
	}
	if fn_obj != nil && fn_obj.type == .FUNCTION {
		fn_copy := object.copy(fn_obj) or_return
		stack.push(curr_stack, fn_copy)
	}
	value_data := run(synt.branch, stck, g_debug) or_return
	if value_data == nil do return nil, .OK
	value := object.copy(value_data) or_return
	return value, .OK
}
