package main

import "core:fmt"
import "evaluation"
import "parser"
import "scan"
import "source_code"
import "stack"
import "sys"
import "token_list"
import "types"
import "vm"

main :: proc() {
	src, src_err := source_code.from_file("test.jonx")
	if sys.is_error(src_err) {
		fmt.printf("%s\n", src_err)
	}
	tokens, tokens_err := scan.run(src)
	if sys.is_error(tokens_err) {
		sys.print_error(tokens_err, tokens)
	}
	synt, synt_err := parser.run(tokens, nil)
	if sys.is_error(synt_err) {
		sys.print_error(synt_err, tokens)
	}
	curr_vm, curr_vm_err := vm.create()
	if sys.is_error(curr_vm_err) {
		sys.print_error(curr_vm_err, tokens)
	}
	curr_stack, curr_stack_err := stack.create()
	if sys.is_error(curr_stack_err) {
		sys.print_error(curr_stack_err, tokens)
	}
	vm_err := vm.push_frame(curr_vm, curr_stack, false)
	if sys.is_error(vm_err) {
		sys.print_error(vm_err, tokens)
	}

	obj, obj_err := evaluation.run(synt, curr_vm)
	if sys.is_error(obj_err) {
		sys.print_error(obj_err, tokens)
	}
	for i in 0 ..< synt.length {
		syntax_pretty_print(synt.statements[i], 0)
	}
	source_code.remove(src)
	token_list.remove(tokens)
}

token_type_to_string :: proc(type: types.token_type_t) -> string {
	#partial switch type {
	case .IDENTIFIER:
		return "IDENTIFIER"
	case .NUMBER:
		return "NUMBER"
	case .STRING_WRAPPER:
		return "STRING"
	case .TRUE:
		return "TRUE"
	case .FALSE:
		return "FALSE"
	case .NIL:
		return "NIL"
	case .PLUS:
		return "PLUS (+)"
	case .MINUS:
		return "MINUS (-)"
	case .STAR:
		return "STAR (*)"
	case .SLASH:
		return "SLASH (/)"
	case .MODULUS:
		return "MODULUS (%)"
	case .DOT_DOT:
		return "STRING_ADD (..)"
	case .EQUAL_EQUAL:
		return "EQUAL_EQUAL (==)"
	case .BANG_EQUAL:
		return "NOT_EQUAL (!=)"
	case .GREATER:
		return "GREATER (>)"
	case .GREATER_EQUAL:
		return "GREATER_EQUAL (>=)"
	case .LESS:
		return "LESS (<)"
	case .LESS_EQUAL:
		return "LESS_EQUAL (<=)"
	case .EQUAL:
		return "ASSIGN (=)"
	case .PLUS_EQUAL:
		return "PLUS_ASSIGN (+=)"
	case .MINUS_EQUAL:
		return "MINUS_ASSIGN (-=)"
	case .STAR_EQUAL:
		return "STAR_ASSIGN (*=)"
	case .SLASH_EQUAL:
		return "SLASH_ASSIGN (/=)"
	case .BANG:
		return "BANG (!)"
	case .COLON:
		return "COLON (:)"
	case .COLON_HAT:
		return "COLON_HAT (:^)"
	case .LEFT_PAREN:
		return "LEFT_PAREN"
	case .RIGHT_PAREN:
		return "RIGHT_PAREN"
	case:
		return "OTHER" // Acts as the default case
	}
}

syntax_pretty_print :: proc(syntax: ^types.syntax_t, indent: int) {
	if syntax == nil {
		return
	}
	for _ in 0 ..< indent {
		fmt.print("  ")
	}
	if syntax.token != nil {
		type_name := token_type_to_string(syntax.token.type)
		if syntax.token.literal != "" {
			fmt.printf("%s: '%s'\n", type_name, syntax.token.literal)
		} else {
			fmt.printf("%s\n", type_name)
		}
	} else {
		fmt.println("UNKNOWN syntax")
	}
	if syntax.left != nil || syntax.right != nil {
		syntax_pretty_print(syntax.left, indent + 1)
		syntax_pretty_print(syntax.right, indent + 1)
	}
}
