package evaluator

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"

g_debug: bool

run :: proc(
	prog: ^types.program_t,
	stck: ^types.vm_t,
	debug_mode: bool,
) -> (
	^types.object_t,
	types.exit_codes,
) {
	if prog == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	g_debug = debug_mode
	prog.pointer = 0
	value: ^types.object_t
	for prog.pointer < prog.length && !prog.exit {
		if prog.exit {
			break
		}
		if prog.continueing {
			prog.pointer = prog.length
			prog.continueing = false
			continue
		}
		value_err: types.exit_codes
		value, value_err = eval_primary_expression(prog.statements[prog.pointer], stck, prog)
		if sys.is_error(value_err) {
			return nil, value_err
		}
		prog.pointer += 1
	}
	if prog.exit {
		return prog.ret_value, .OK
	}
	return value, .OK
}

branch :: proc(synt: ^types.syntax_t, stck: ^types.vm_t) -> (^types.object_t, types.exit_codes) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL
	}
	// -------------------------------------------------------------
	// Path 1: synt.args == nil
	// -------------------------------------------------------------
	if synt.args == nil {
		new_stack, new_stack_err := stack.create()
		if sys.is_error(new_stack_err) {
			return nil, new_stack_err
		}
		vm_err := vm.push_frame(stck, new_stack, true)
		if sys.is_error(vm_err) {
			return nil, vm_err
		}
		defer vm_err = vm.pop_frame(stck)
		if sys.is_error(vm_err) {
			return nil, vm_err
		}
		value_data, value_data_err := run(synt.branch, stck, g_debug)
		if sys.is_error(value_data_err) {
			return nil, value_data_err
		}
		if value_data == nil {
			return nil, .OK
		}
		value, value_err := object.copy(value_data)
		if sys.is_error(value_err) && value_err != .OBJECT_IS_NIL {
			return nil, value_err
		}
		return value, .OK
	}
	// -------------------------------------------------------------
	// Path 2: synt.args != nil
	// -------------------------------------------------------------
	new_stack, new_stack_err := stack.create()
	if sys.is_error(new_stack_err) {
		return nil, new_stack_err
	}
	vm_prev, vm_prev_err := vm.current_frame(stck)
	if sys.is_error(vm_prev_err) {
		return nil, vm_prev_err
	}
	arg_vals: [dynamic]^types.object_t
	defer delete(arg_vals)
	for &i in synt.value.branch.statements {
		arg_val, arg_vals_err := eval_primary_expression(i, stck, nil)
		if sys.is_error(arg_vals_err) {
			return nil, arg_vals_err
		}
		append(&arg_vals, arg_val)
	}
	vm_err := vm.push_frame(stck, new_stack, false)
	if sys.is_error(vm_err) {
		return nil, vm_err
	}
	defer vm_err = vm.pop_frame(stck)
	if sys.is_error(vm_err) {
		return nil, vm_err
	}
	_, eval_err := run(synt.args, stck, g_debug)
	if sys.is_error(eval_err) {
		return nil, eval_err
	}
	curr_stack, curr_stack_err := vm.current_frame(stck)
	if sys.is_error(curr_stack_err) {
		return nil, curr_stack_err
	}
	if curr_stack.count - curr_stack.parent_references != synt.value.branch.length {
		return nil, .INCORRECT_NUMBER_OF_REFERENCES
	}
	for i := curr_stack.parent_references; i < curr_stack.count; i += 1 {
		idx := i - curr_stack.parent_references
		curr_stack.data[i].data = arg_vals[idx].data
		curr_stack.data[i].type = arg_vals[idx].type
	}
	value_data, value_data_err := run(synt.branch, stck, g_debug)
	if sys.is_error(value_data_err) {
		return nil, value_data_err
	}
	if value_data == nil {
		return nil, .OK
	}
	value, value_err := object.copy(value_data)
	if sys.is_error(value_err) && value_err != .OBJECT_IS_NIL {
		return nil, value_err
	}
	return value, .OK
}
