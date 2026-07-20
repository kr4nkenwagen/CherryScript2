package evaluation

import "../predefined_functions"
import "../stack"
import "../sys"
import "../types"
import "../vm"

eval_while :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if syntax == nil {
		return .OBJECT_IS_NIL
	}
	condition, cond_err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(cond_err) {
		return cond_err
	}
	if condition.type != .BOOL {
		return .TYPE_MISMATCH
	}
	for condition.data.(bool) == true {
		_, branch_err := branch(syntax, vm)
		if sys.is_error(branch_err) {
			return branch_err
		}
		condition, cond_err = eval_primary_expression(syntax.value, vm, program)
		if sys.is_error(cond_err) {
			return cond_err
		}
	}
	return .OK
}

eval_for :: proc(
	syntax: ^types.syntax_t,
	vmem: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	if syntax == nil {
		return .OBJECT_IS_NIL
	}
	new_stack, new_stack_err := stack.create()
	if sys.is_error(new_stack_err) {
		return new_stack_err
	}
	err := vm.push_frame(vmem, new_stack, true)
	if sys.is_error(err) {
		return err
	}
	_, init_err := eval_primary_expression(syntax.left, vmem, program)
	if sys.is_error(init_err) {
		err = vm.pop_frame(vmem)
		if sys.is_error(err) {
			return err
		}
		return init_err
	}
	condition, cond_err := eval_primary_expression(syntax.value, vmem, program)
	if sys.is_error(cond_err) {
		err = vm.pop_frame(vmem)
		if sys.is_error(err) {
			return err
		}
		return cond_err
	}
	if condition.type != .BOOL {
		return .TYPE_MISMATCH
	}
	for condition.data.(bool) == true {
		_, branch_err := branch(syntax, vmem)
		if sys.is_error(branch_err) {
			return branch_err
		}
		_, post_err := eval_primary_expression(syntax.right, vmem, program)
		if sys.is_error(post_err) {
			return post_err
		}
		condition, cond_err = eval_primary_expression(syntax.value, vmem, program)
		if sys.is_error(cond_err) {
			return cond_err
		}
	}
	err = vm.pop_frame(vmem)
	if sys.is_error(err) {
		return err
	}
	return .OK
}

eval_if :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_syntax := syntax
	for curr_syntax != nil &&
	    (curr_syntax.token.type == .IF ||
			    curr_syntax.token.type == .ELSE_IF ||
			    curr_syntax.token.type == .ELSE) {
		condition, cond_err := eval_primary_expression(curr_syntax.value, vm, program)
		if sys.is_error(cond_err) do return cond_err

		if curr_syntax.token.type == .ELSE || condition.data.(bool) == true {
			_, branch_err := branch(curr_syntax, vm)
			return branch_err
		}
		curr_syntax = curr_syntax.right
	}
	return .OK
}

eval_break :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_prog := program
	for curr_prog.type != .LOOP {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.exit = true
	return .OK
}

eval_continue :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_prog := program
	for curr_prog.type != .LOOP {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.continueing = true
	return .OK
}

eval_return :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	curr_prog := program
	for curr_prog.type != .FUNCTION {
		curr_prog.exit = true
		curr_prog = curr_prog.parent
	}
	curr_prog.exit = true

	val, err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(err) do return err

	curr_prog.ret_value = val
	return .OK
}

eval_out :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	val, err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(err) do return err
	predefined_functions.print(val)
	return .OK
}

eval_error :: proc(
	syntax: ^types.syntax_t,
	vm: ^types.vm_t,
	program: ^types.program_t,
) -> types.exit_codes {
	val, err := eval_primary_expression(syntax.value, vm, program)
	if sys.is_error(err) do return err
	predefined_functions.print(val)
	return .OK
}
