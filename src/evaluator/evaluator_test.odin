package evaluator

import "core:testing"
import "../object"
import "../program"
import "../syntax"
import "../token"
import "../types"

mki :: proc(v: int) -> ^types.object_t {
	o, _ := object.create_int(v)
	return o
}

mkf :: proc(v: f32) -> ^types.object_t {
	o, _ := object.create_float(v)
	return o
}

mks :: proc(v: string) -> ^types.object_t {
	o, _ := object.create_string(v)
	return o
}

host :: proc() -> ^types.program_t {
	p, _ := program.create(nil)
	return p
}

dl :: proc(l: [dynamic]^types.object_t) {
	delete(l)
}

@(test)
str_contains_found :: proc(t: ^testing.T) {
	args: [dynamic]^types.object_t
	append(&args, mks("hello"))
	append(&args, mks("ell"))
	obj, code := str_contains(args[:])
	testing.expectf(t, code == .OK && obj.data.(bool) == true, "contains should be true")
	dl(args)
}

@(test)
str_contains_missing :: proc(t: ^testing.T) {
	args: [dynamic]^types.object_t
	append(&args, mks("hello"))
	append(&args, mks("z"))
	obj, _ := str_contains(args[:])
	testing.expectf(t, obj.data.(bool) == false, "contains should be false")
	dl(args)
}

@(test)
str_contains_errors :: proc(t: ^testing.T) {
	args: [dynamic]^types.object_t
	append(&args, mks("a"))
	obj, code := str_contains(args[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_CONTAINS, "arg count: %v", code)
	dl(args)

	args2: [dynamic]^types.object_t
	append(&args2, mki(1))
	append(&args2, mks("a"))
	obj, code = str_contains(args2[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_PARAMETER_TYPE_IN_STRING_CONTAINS, "type: %v", code)
	dl(args2)
}

@(test)
str_first_last_index_of :: proc(t: ^testing.T) {
	args: [dynamic]^types.object_t
	append(&args, mks("banana"))
	append(&args, mks("na"))
	obj, code := str_first_index_of(args[:])
	testing.expectf(t, code == .OK && obj.data.(int) == 2, "first index should be 2")
	dl(args)

	args2: [dynamic]^types.object_t
	append(&args2, mks("banana"))
	append(&args2, mks("na"))
	obj, _ = str_last_index_of(args2[:])
	testing.expectf(t, obj.data.(int) == 4, "last index should be 4")
	dl(args2)
}

@(test)
str_first_index_of_from_test :: proc(t: ^testing.T) {
	args: [dynamic]^types.object_t
	append(&args, mks("banana"))
	append(&args, mks("a"))
	append(&args, mki(3))
	obj, code := str_first_index_of_from(args[:])
	testing.expectf(t, code == .OK && obj.data.(int) == 0, "index from 3 should be 0, got %d", obj.data.(int))
	dl(args)
}

@(test)
str_trim_variants :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mks("  hi  "))
	obj, _ := str_trim_start(a[:])
	testing.expectf(t, obj.data.(string) == "hi  ", "trim_start: %s", obj.data.(string))
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mks("  hi  "))
	obj, _ = str_trim_end(b[:])
	testing.expectf(t, obj.data.(string) == "  hi", "trim_end: %s", obj.data.(string))
	dl(b)

	c: [dynamic]^types.object_t
	append(&c, mks("  hi  "))
	obj, _ = str_trim(c[:])
	testing.expectf(t, obj.data.(string) == "hi", "trim: %s", obj.data.(string))
	dl(c)
}

@(test)
str_case_variants :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mks("Hi"))
	obj, _ := str_to_upper(a[:])
	testing.expectf(t, obj.data.(string) == "HI", "to_upper: %s", obj.data.(string))
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mks("Hi"))
	obj, _ = str_to_lower(b[:])
	testing.expectf(t, obj.data.(string) == "hi", "to_lower: %s", obj.data.(string))
	dl(b)
}

@(test)
str_pad_variants :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mks("ab"))
	append(&a, mki(2))
	obj, _ := str_pad_start(a[:])
	testing.expectf(t, obj.data.(string) == "  ab", "pad_start: %s", obj.data.(string))
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mks("ab"))
	append(&b, mki(2))
	obj, _ = str_pad_end(b[:])
	testing.expectf(t, obj.data.(string) == "ab  ", "pad_end: %s", obj.data.(string))
	dl(b)
}

@(test)
str_replace_all_basic :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mks("a1b1"))
	append(&a, mks("1"))
	append(&a, mks("2"))
	obj, code := str_replace_all(a[:])
	testing.expectf(t, code == .OK && obj.data.(string) == "a2b2", "got: %s", obj.data.(string))
	dl(a)
}

@(test)
str_replace_all_errors :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mks("a"))
	obj, code := str_replace_all(a[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_NUMBER_OF_PARAMETERS_IN_STRING_REPLACE_ALL, "count: %v", code)
	dl(a)
}

@(test)
math_max_min :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(3))
	append(&a, mki(5))
	obj, code := math_max(a[:])
	testing.expectf(t, code == .OK && obj.data.(f32) == 5.0, "max should be 5")
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mki(3))
	append(&b, mki(5))
	obj, _ = math_min(b[:])
	testing.expectf(t, obj.data.(f32) == 3.0, "min should be 3")
	dl(b)
}

@(test)
math_abs_sqrt_sign :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(-5))
	obj, code := math_abs(a[:])
	testing.expectf(t, code == .OK && obj.data.(f32) == 5.0, "abs should be 5")
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mki(9))
	obj, _ = math_sqrt(b[:])
	testing.expectf(t, obj.data.(f32) == 3.0, "sqrt(9) should be 3")
	dl(b)

	c: [dynamic]^types.object_t
	append(&c, mki(-3))
	obj, _ = math_sign(c[:])
	testing.expectf(t, obj.data.(f32) == -1.0, "sign(-3) should be -1")
	dl(c)
}

@(test)
math_floor_ceil_round_trunc :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mkf(2.7))
	obj, _ := math_floor(a[:])
	testing.expectf(t, obj.data.(f32) == 2.0, "floor(2.7) should be 2")
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mkf(2.1))
	obj, _ = math_ceil(b[:])
	testing.expectf(t, obj.data.(f32) == 3.0, "ceil(2.1) should be 3")
	dl(b)

	c: [dynamic]^types.object_t
	append(&c, mkf(2.7))
	obj, _ = math_round(c[:])
	testing.expectf(t, obj.data.(f32) == 3.0, "round(2.7) should be 3")
	dl(c)

	d: [dynamic]^types.object_t
	append(&d, mkf(2.9))
	obj, _ = math_trunc(d[:])
	testing.expectf(t, obj.data.(f32) == 2.0, "trunc(2.9) should be 2")
	dl(d)
}

@(test)
math_min_max_clamps :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(50))
	append(&a, mki(0))
	append(&a, mki(10))
	obj, code := math_min_max(a[:])
	testing.expectf(t, code == .OK && obj.data.(f32) == 10.0, "clamp(50,0,10) should be 10")
	dl(a)
}

@(test)
math_min_max_invalid_errors :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(5))
	append(&a, mki(10))
	append(&a, mki(0))
	obj, code := math_min_max(a[:])
	testing.expectf(t, obj == nil && code == .MIN_IS_GREATER_THAN_MAX_IN_MATH_MIN_MAX, "code: %v", code)
	dl(a)
}

@(test)
math_lerp_test :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mkf(0.5))
	append(&a, mki(0))
	append(&a, mki(10))
	obj, code := math_lerp(a[:])
	testing.expectf(t, code == .OK && obj.data.(f32) == 5.0, "lerp(0.5,0,10) should be 5")
	dl(a)
}

@(test)
math_log_hypot_atan2 :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(8))
	append(&a, mki(2))
	obj, code := math_log(a[:])
	testing.expectf(t, code == .OK && obj.data.(f32) == 3.0, "log8(8) should be 3")
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mki(3))
	append(&b, mki(4))
	obj, _ = math_hypot(b[:])
	testing.expectf(t, obj.data.(f32) == 5.0, "hypot(3,4) should be 5")
	dl(b)

	c: [dynamic]^types.object_t
	append(&c, mki(0))
	append(&c, mki(1))
	obj, _ = math_atan2(c[:])
	testing.expectf(t, obj.data.(f32) == 0.0, "atan2(0,1) should be 0")
	dl(c)
}

@(test)
math_trig_zero_angles :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(0))
	obj, code := math_sin(a[:])
	testing.expectf(t, code == .OK && obj.data.(f32) == 0.0, "sin(0) should be 0")
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mki(0))
	obj, _ = math_cos(b[:])
	testing.expectf(t, obj.data.(f32) == 1.0, "cos(0) should be 1")
	dl(b)

	c: [dynamic]^types.object_t
	append(&c, mki(0))
	obj, _ = math_tan(c[:])
	testing.expectf(t, obj.data.(f32) == 0.0, "tan(0) should be 0")
	dl(c)
}

@(test)
math_random_range_valid :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(0))
	append(&a, mki(1))
	obj, code := math_random_range(a[:])
	testing.expectf(t, code == .OK && obj.type == .FLOAT, "random_range should be float")
	dl(a)
}

@(test)
math_random_range_invalid_errors :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(5))
	append(&a, mki(1))
	obj, code := math_random_range(a[:])
	testing.expectf(t, obj == nil && code == .MIN_IS_GREATER_THAN_MAX_IN_MATH_RANDOM_RANGE, "code: %v", code)
	dl(a)
}

@(test)
math_arg_count_errors :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mki(1))
	append(&a, mki(2))
	obj, code := math_abs(a[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_ABS, "abs: %v", code)
	dl(a)

	b: [dynamic]^types.object_t
	obj, code = math_sqrt(b[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_SQRT, "sqrt: %v", code)
	dl(b)

	c: [dynamic]^types.object_t
	append(&c, mki(1))
	obj, code = math_lerp(c[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_NUMBER_OF_PARAMETERS_IN_MATH_LERP, "lerp: %v", code)
	dl(c)
}

@(test)
math_type_errors :: proc(t: ^testing.T) {
	a: [dynamic]^types.object_t
	append(&a, mks("x"))
	obj, code := math_abs(a[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_PARAMETER_TYPE_IN_MATH_ABS, "abs: %v", code)
	dl(a)

	b: [dynamic]^types.object_t
	append(&b, mks("x"))
	obj, code = math_sqrt(b[:])
	testing.expectf(t, obj == nil && code == .INCORRECT_PARAMETER_TYPE_IN_MATH_SQRT, "sqrt: %v", code)
	dl(b)
}

@(test)
divide_by_zero_detects :: proc(t: ^testing.T) {
	z := mki(0)
	n := mki(5)
	testing.expectf(t, divide_by_zero(z, n), "a==0 should be div-by-zero")
	testing.expectf(t, divide_by_zero(n, z), "b==0 should be div-by-zero")
	testing.expectf(t, !divide_by_zero(n, mki(2)), "non-zero should not be div-by-zero")
	testing.expectf(t, divide_by_zero(mkf(0.0), n), "float a==0 should be div-by-zero")
}

@(test)
eval_number_integer :: proc(t: ^testing.T) {
	p := host()
	s, _ := syntax.create()
	tok, _ := token.create(nil, .NUMBER, "42")
	s.token = tok
	obj, code := eval_number(s, p)
	testing.expectf(t, code == .OK && obj.type == .INT, "42 should be INT")
	testing.expectf(t, obj.data.(int) == 42, "value should be 42, got %d", obj.data.(int))
}

@(test)
eval_number_float :: proc(t: ^testing.T) {
	p := host()
	s, _ := syntax.create()
	tok, _ := token.create(nil, .NUMBER, "3.5")
	s.token = tok
	obj, _ := eval_number(s, p)
	testing.expectf(t, obj.type == .FLOAT, "3.5 should be FLOAT")
	testing.expectf(t, obj.data.(f32) == 3.5, "value should be 3.5")
}

@(test)
run_nil_errors :: proc(t: ^testing.T) {
	obj, code := run(nil, nil)
	testing.expectf(t, obj == nil && code == .OBJECT_IS_NIL_IN_EVAL_RUN, "code: %v", code)
}

@(test)
branch_nil_errors :: proc(t: ^testing.T) {
	obj, code := branch(nil, nil, nil)
	testing.expectf(t, obj == nil && code == .OBJECT_IS_NIL_IN_EVAL_BRANCH, "code: %v", code)
}

@(test)
eval_while_nil_errors :: proc(t: ^testing.T) {
	code := eval_while(nil, nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_EVAL_WHILE, "code: %v", code)
}

@(test)
eval_for_nil_errors :: proc(t: ^testing.T) {
	code := eval_for(nil, nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_EVAL_FOR, "code: %v", code)
}

@(test)
variable_declarations_nil_errors :: proc(t: ^testing.T) {
	code := variable_declarations(nil, nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_VARIABLE_DECLARATION, "code: %v", code)
}

@(test)
eval_variable_remove_nil_errors :: proc(t: ^testing.T) {
	code := eval_variable_remove(nil, nil, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_EVAL_VARIABLE_REMOVE, "code: %v", code)
}

@(test)
eval_array_declaration_nil_errors :: proc(t: ^testing.T) {
	obj, code := eval_array_declaration(nil, nil, nil)
	testing.expectf(t, obj == nil && code == .OBJECT_IS_NIL_EVAL_ARRAY_DECLARATION, "code: %v", code)
}

@(test)
eval_global_non_var_errors :: proc(t: ^testing.T) {
	p := host()
	s, _ := syntax.create()
	v, _ := syntax.create()
	tok, _ := token.create(nil, .NUMBER, "1")
	v.token = tok
	s.value = v
	code := eval_global(s, nil, p)
	testing.expectf(t, code == .OBJECT_NOT_VARIABLE_OR_FUNCTION_CANT_BE_GLOBAL_IN_EVAL_GLOBAL, "code: %v", code)
}

@(test)
eval_return_sets_exit :: proc(t: ^testing.T) {
	p := host()
	s, _ := syntax.create()
	code := eval_return(s, nil, p)
	testing.expectf(t, code == .OK, "eval_return failed: %v", code)
	testing.expectf(t, p.exit == true, "program exit should be set")
}