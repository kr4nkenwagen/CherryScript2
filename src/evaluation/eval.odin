package evaluation

import "../object"
import "../stack"
import "../sys"
import "../types"
import "../vm"

run :: proc(prog: ^types.program_t, vmem: ^types.vm_t) -> (^types.object_t, types.exit_codes) {
	if prog == nil {
		return nil, types.exit_codes.OBJECT_IS_NIL
	}
	prog.pointer = 0
	value: ^types.object_t
	for prog.pointer < prog.length {
		if prog.exit {
			break
		}
		if prog.continueing {
			prog.pointer += 1
			prog.continueing = false
			continue
		}
		value_err: types.exit_codes
		value, value_err = eval_primary_expression(prog.statements[prog.pointer], vmem, prog)
		if sys.is_error(value_err) {
			return nil, value_err
		}
		prog.pointer += 1
	}
	return value, .OK
}

branch :: proc(synt: ^types.syntax_t, vmem: ^types.vm_t) -> (^types.object_t, types.exit_codes) {
	if synt == nil {
		return nil, .OBJECT_IS_NIL
	}
	if synt.args == nil {
		new_stack, new_stack_err := stack.create()
		if sys.is_error(new_stack_err) {
			return nil, new_stack_err
		}
		vm_err := vm.push_frame(vmem, new_stack, true)
		if sys.is_error(vm_err) {
			return nil, vm_err
		}
		value_data, value_data_err := run(synt.branch, vmem)
		if sys.is_error(value_data_err) {
			return nil, value_data_err
		}
		if value_data == nil {
			return value_data, .OK
		}
		value, value_err := object.copy(value_data)
		if sys.is_error(value_err) {
			return nil, value_err
		}
		vm_err = vm.pop_frame(vmem)
		if sys.is_error(vm_err) {
			return nil, vm_err
		}
		return value, .OK
	}
	arg_vals, arg_vals_err := eval_array_declaration(synt.value, vmem, synt.branch)
	if sys.is_error(arg_vals_err) {
		return nil, arg_vals_err
	}
	new_stack, new_stack_err := stack.create()
	if sys.is_error(new_stack_err) {
		return nil, new_stack_err
	}
	vm_err := vm.push_frame(vmem, new_stack, false)
	if sys.is_error(vm_err) {
		return nil, vm_err
	}
	_, eval_err := run(synt.args, vmem)
	if sys.is_error(eval_err) {
		return nil, eval_err
	}
	curr_stack, curr_stack_err := vm.current_frame(vmem)
	if sys.is_error(curr_stack_err) {
		return nil, curr_stack_err
	}
	if curr_stack.count - curr_stack.parent_references !=
	   arg_vals.data.(types.object_array_t).count {
		return nil, .INCORRECT_NUMBER_OF_REFERENCES
	}
	for i := curr_stack.parent_references; i < curr_stack.count; i += 1 {
		curr_stack.data[i].data =
			arg_vals.data.(types.object_array_t).value[i - curr_stack.parent_references].data
		curr_stack.data[i].type =
			arg_vals.data.(types.object_array_t).value[i - curr_stack.parent_references].type
	}
	value_data, value_data_err := run(synt.branch, vmem)
	if sys.is_error(value_data_err) {
		return nil, value_data_err
	}
	value, value_err := object.copy(value_data)
	if sys.is_error(value_err) {
		return nil, value_err
	}
	vm_err = vm.pop_frame(vmem)
	if sys.is_error(vm_err) {
		return nil, vm_err
	}
	return value, .OK
}
