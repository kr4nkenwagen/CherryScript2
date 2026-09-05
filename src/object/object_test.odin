package object

import "core:testing"
import "core:strings"
import "../syntax"
import "../types"

@(test)
create_int_value :: proc(t: ^testing.T) {
	o, code := create_int(7)
	testing.expectf(t, code == .OK, "create_int failed: %v", code)
	testing.expectf(t, o != nil, "create_int should return object")
	testing.expectf(t, o.type == .INT, "type should be INT")
	testing.expectf(t, o.data.(int) == 7, "data should hold 7")
	remove(o)
}

@(test)
create_bool_value :: proc(t: ^testing.T) {
	o, _ := create_bool(true)
	testing.expectf(t, o.type == .BOOL, "type should be BOOL")
	testing.expectf(t, o.data.(bool) == true, "data should hold true")
	remove(o)
}

@(test)
create_float_value :: proc(t: ^testing.T) {
	o, _ := create_float(f32(2.5))
	testing.expectf(t, o.type == .FLOAT, "type should be FLOAT")
	testing.expectf(t, o.data.(f32) == f32(2.5), "data should hold 2.5")
	remove(o)
}

@(test)
create_string_value :: proc(t: ^testing.T) {
	o, _ := create_string("hi")
	testing.expectf(t, o.type == .STRING, "type should be STRING")
	testing.expectf(t, o.data.(string) == "hi", "data should hold 'hi'")
	remove(o)
}

@(test)
create_array_empty :: proc(t: ^testing.T) {
	o, _ := create_array()
	testing.expectf(t, o.type == .ARRAY, "type should be ARRAY")
	testing.expectf(t, o.data.(types.object_array_t).count == 0, "count should start at 0")
	remove(o)
}

@(test)
create_null_value :: proc(t: ^testing.T) {
	o, _ := create_null()
	testing.expectf(t, o.type == types.object_type_t.NULL, "type should be NULL")
	testing.expectf(t, !o.is_marked, "is_marked should be false")
	remove(o)
}

@(test)
create_funct_ok :: proc(t: ^testing.T) {
	s, _ := syntax.create()
	o, code := create_funct(s)
	testing.expectf(t, code == .OK, "create_funct failed: %v", code)
	testing.expectf(t, o.type == .FUNCTION, "type should be FUNCTION")
	remove(o)
}

@(test)
create_funct_nil_syntax_errors :: proc(t: ^testing.T) {
	o, code := create_funct(nil)
	testing.expectf(t, o == nil, "should return nil")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_CREATE_FUNCT, "wrong code: %v", code)
}

@(test)
create_file_value :: proc(t: ^testing.T) {
	o, _ := create_file("x.txt")
	testing.expectf(t, o.type == .FILE, "type should be FILE")
	testing.expectf(t, o.data.(types.object_file_t).name == "x.txt", "should hold filename")
	remove(o)
}

@(test)
create_json_empty_defaults_to_brackets :: proc(t: ^testing.T) {
	o, code := create_json("")
	testing.expectf(t, code == .OK, "create_json failed: %v", code)
	testing.expectf(t, o.type == .JSON, "type should be JSON")
	remove(o)
}

@(test)
create_json_invalid_errors :: proc(t: ^testing.T) {
	o, code := create_json("not json")
	testing.expectf(t, o == nil, "invalid json should return nil")
	testing.expectf(t, code == .FAILED_TO_PARSE_JSON_IN_CREATE_JSON, "wrong code: %v", code)
}

@(test)
set_null_when_not_null :: proc(t: ^testing.T) {
	o, _ := create_int(1)
	code := set_null(o)
	testing.expectf(t, code == .OK, "set_null failed: %v", code)
	testing.expectf(t, o.type == types.object_type_t.NULL, "type should become NULL")
	remove(o)
}

@(test)
set_null_nil_errors :: proc(t: ^testing.T) {
	code := set_null(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_SET_NULL, "wrong code: %v", code)
}

@(test)
length_variant :: proc(t: ^testing.T) {
	io, _ := create_int(123)
	n, code := length(io)
	testing.expectf(t, code == .OK && n == 3, "int length should be 3, got %d", n)
	remove(io)

	fo, _ := create_float(f32(12.50))
	n, _ = length(fo)
	testing.expectf(t, n > 0, "float length should be positive")
	remove(fo)

	so, _ := create_string("hello")
	n, _ = length(so)
	testing.expectf(t, n == 5, "string length should be 5, got %d", n)
	remove(so)
}

@(test)
length_array_json :: proc(t: ^testing.T) {
	ao, _ := create_array()
	n, _ := length(ao)
	testing.expectf(t, n == 0, "empty array length should be 0, got %d", n)
	remove(ao)

	jo, _ := create_json("{}")
	n, _ = length(jo)
	testing.expectf(t, n == 0, "empty json length should be 0, got %d", n)
	remove(jo)
}

@(test)
length_unknown_errors :: proc(t: ^testing.T) {
	bo, _ := create_bool(true)
	n, code := length(bo)
	testing.expectf(t, n == -1, "unknown type length should be -1")
	testing.expectf(t, code == .OBJECT_IS_UNKNOWN_TYPE_IN_LENGTH, "wrong code: %v", code)
	remove(bo)
}

@(test)
length_nil_errors :: proc(t: ^testing.T) {
	n, code := length(nil)
	testing.expectf(t, n == -1, "nil length should be -1")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_LENGTH, "wrong code: %v", code)
}

@(test)
remove_nil_errors :: proc(t: ^testing.T) {
	code := remove(nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_OBJECT_REMOVE, "wrong code: %v", code)
}

@(test)
copy_shallow :: proc(t: ^testing.T) {
	src, _ := create_int(5)
	c, code := copy(src)
	testing.expectf(t, code == .OK, "copy failed: %v", code)
	testing.expectf(t, c != src, "copy should be a distinct object")
	testing.expectf(t, c.type == src.type, "type should match")
	testing.expectf(t, c.data.(int) == src.data.(int), "data should match")
	remove(c)
	remove(src)
}

@(test)
copy_nil_errors :: proc(t: ^testing.T) {
	c, code := copy(nil)
	testing.expectf(t, c == nil, "copy(nil) should return nil")
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_OBJECT_COPY, "wrong code: %v", code)
}

@(test)
array_set_appends :: proc(t: ^testing.T) {
	arr, _ := create_array()
	item, _ := create_int(1)
	code := array_set(arr, 0, item)
	testing.expectf(t, code == .OK, "array_set failed: %v", code)
	testing.expectf(t, arr.data.(types.object_array_t).count == 1, "count should be 1")
	testing.expectf(t, arr.data.(types.object_array_t).value[0] == item, "should reference item")
	remove(arr)
}

@(test)
array_set_replaces_existing_index :: proc(t: ^testing.T) {
	arr, _ := create_array()
	one, _ := create_int(1)
	two, _ := create_int(2)
	array_set(arr, 0, one)
	code := array_set(arr, 0, two)
	testing.expectf(t, code == .OK, "replace failed: %v", code)
	testing.expectf(t, arr.data.(types.object_array_t).value[0] == two, "should hold new item")
	testing.expectf(t, arr.data.(types.object_array_t).count == 1, "count should stay 1")
	remove(arr)
}

@(test)
array_set_grows_beyond_count :: proc(t: ^testing.T) {
	arr, _ := create_array()
	item, _ := create_int(9)
	code := array_set(arr, 3, item)
	testing.expectf(t, code == .OK, "grow failed: %v", code)
	testing.expectf(t, arr.data.(types.object_array_t).count == 4, "count should be 4, got %d", arr.data.(types.object_array_t).count)
	testing.expectf(t, arr.data.(types.object_array_t).value[3] == item, "last slot should hold item")
	remove(arr)
}

@(test)
array_set_errors :: proc(t: ^testing.T) {
	code := array_set(nil, 0, nil)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_ARRAY_SET, "nil arr wrong code: %v", code)

	not_arr, _ := create_int(1)
	code = array_set(not_arr, 0, nil)
	testing.expectf(t, code == .ARRAY_OPERATION_ON_NON_ARRAY_OBJECT_IN_ARRAY_SET, "non-array wrong code: %v", code)
	remove(not_arr)
}

@(test)
array_get_in_bounds :: proc(t: ^testing.T) {
	arr, _ := create_array()
	item, _ := create_int(4)
	array_set(arr, 0, item)
	got, code := array_get(arr, 0)
	testing.expectf(t, code == .OK, "array_get failed: %v", code)
	testing.expectf(t, got == item, "should return the item")
	remove(arr)
}

@(test)
array_get_grows_out_of_bounds :: proc(t: ^testing.T) {
	arr, _ := create_array()
	got, code := array_get(arr, 2)
	testing.expectf(t, code == .OK, "array_get grow failed: %v", code)
	testing.expectf(t, got != nil, "out-of-bounds get should produce an item")
	testing.expectf(t, arr.data.(types.object_array_t).count == 3, "count should grow to 3, got %d", arr.data.(types.object_array_t).count)
	remove(arr)
}

@(test)
array_get_errors :: proc(t: ^testing.T) {
	got, code := array_get(nil, 0)
	testing.expectf(t, got == nil && code == .OBJECT_IS_NIL_IN_ARRAY_GET, "nil arr wrong code: %v", code)

	not_arr, _ := create_int(1)
	got, code = array_get(not_arr, 0)
	testing.expectf(t, got == nil && code == .ARRAY_OPERATION_ON_NON_ARRAY_OBJECT_IN_ARRAY_GET, "non-array wrong code: %v", code)
	remove(not_arr)
}

@(test)
get_numeric_value_variants :: proc(t: ^testing.T) {
	io, _ := create_int(3)
	val, ok := get_numeric_value(io)
	testing.expectf(t, ok && val == 3.0, "int should be numeric")
	remove(io)

	fo, _ := create_float(f32(4.5))
	val, ok = get_numeric_value(fo)
	testing.expectf(t, ok && val == 4.5, "float should be numeric")
	remove(fo)

	bo, _ := create_bool(true)
	val, ok = get_numeric_value(bo)
	testing.expectf(t, ok && val == 1.0, "true should be 1")
	remove(bo)

	val, ok = get_numeric_value(nil)
	testing.expectf(t, !ok, "nil should not be numeric")
}

@(test)
equals_numeric_and_nil_errors :: proc(t: ^testing.T) {
	a, _ := create_int(2)
	b, _ := create_int(2)
	res, code := equals(a, b)
	testing.expectf(t, code == .OK && res.data.(bool) == true, "equal ints should be true")
	remove(res)
	remove(a)
	remove(b)

	x, _ := create_int(2)
	y, _ := create_int(3)
	res, _ = equals(x, y)
	testing.expectf(t, res.data.(bool) == false, "unequal ints should be false")
	remove(res)
	remove(x)
	remove(y)

	res, code = equals(nil, y)
	testing.expectf(t, res == nil && code == .OBJECT_IS_NIL_ON_OBJECT_EQUAL, "nil wrong code: %v", code)
	remove(y)
}

@(test)
equals_string_and_null :: proc(t: ^testing.T) {
	a, _ := create_string("hi")
	b, _ := create_string("hi")
	res, _ := equals(a, b)
	testing.expectf(t, res.data.(bool) == true, "equal strings should be true")
	remove(res)
	remove(a)
	remove(b)

	n1, _ := create_null()
	n2, _ := create_null()
	res, _ = equals(n1, n2)
	testing.expectf(t, res.data.(bool) == true, "null == null should be true")
	remove(res)
	remove(n1)
	remove(n2)
}

@(test)
less_than_variants :: proc(t: ^testing.T) {
	a, _ := create_int(1)
	b, _ := create_int(2)
	res, code := less(a, b)
	testing.expectf(t, code == .OK && res.data.(bool) == true, "1 < 2 should be true")
	remove(res)
	remove(a)
	remove(b)

	x, _ := create_int(5)
	y, _ := create_int(4)
	res, _ = less(x, y)
	testing.expectf(t, res.data.(bool) == false, "5 < 4 should be false")
	remove(res)

	str, _ := create_string("a")
	res, code = less(str, y)
	testing.expectf(t, res == nil && code == .TYPE_MISMATCH_IN_OBJECT_LESS, "string vs int should mismatch")
	remove(y)
	remove(str)
}

@(test)
greater_equal_null :: proc(t: ^testing.T) {
	a, _ := create_int(3)
	b, _ := create_int(3)
	res, _ := greater_equals(a, b)
	testing.expectf(t, res.data.(bool) == true, "3 >= 3 should be true")
	remove(res)
	remove(a)
	remove(b)

	n1, _ := create_null()
	n2, _ := create_null()
	res, _ = greater_equals(n1, n2)
	testing.expectf(t, res.data.(bool) == true, "null >= null should be true")
	remove(res)
	remove(n1)
	remove(n2)
}

@(test)
add_int_float_string :: proc(t: ^testing.T) {
	a, _ := create_int(2)
	b, _ := create_int(3)
	res, code := add(a, b)
	testing.expectf(t, code == .OK && res.data.(int) == 5, "2+3 should be 5, got %d", res.data.(int))
	remove(res)
	remove(a)
	remove(b)

	sa, _ := create_string("hello ")
	sb, _ := create_string("world")
	res, _ = add(sa, sb)
	testing.expectf(t, res.type == .STRING && res.data.(string) == "hello world", "string concat failed")
	remove(res)
	remove(sa)
	remove(sb)

	bo, _ := create_bool(true)
	res, code = add(bo, sb)
	testing.expectf(t, res == nil && code == .TYPE_MISMATCH_IN_OBJECT_ADD, "bool+string should mismatch")
	remove(bo)
	remove(sb)
}

@(test)
add_nil_errors :: proc(t: ^testing.T) {
	a, _ := create_int(1)
	res, code := add(nil, a)
	testing.expectf(t, res == nil && code == .OBJECT_IS_NIl_in_OBJECT_ADD, "wrong code: %v", code)
	remove(a)
}

@(test)
add_arrays_concatenates :: proc(t: ^testing.T) {
	aa, _ := create_array()
	ab, _ := create_array()
	i1, _ := create_int(1)
	i2, _ := create_int(2)
	array_set(aa, 0, i1)
	array_set(ab, 0, i2)
	res, code := add(aa, ab)
	testing.expectf(t, code == .OK, "array add failed: %v", code)
	testing.expectf(t, res.data.(types.object_array_t).count == 2, "concat array should have 2")
	remove(res)
	remove(aa)
	remove(ab)
}

@(test)
subtract_variants :: proc(t: ^testing.T) {
	a, _ := create_int(10)
	b, _ := create_int(3)
	res, code := subtract(a, b)
	testing.expectf(t, code == .OK && res.data.(int) == 7, "10-3 should be 7, got %d", res.data.(int))
	remove(res)
	remove(a)
	remove(b)

	sa, _ := create_string("a1b1")
	sb, _ := create_string("1")
	res, _ = subtract(sa, sb)
	testing.expectf(t, res.type == .STRING && res.data.(string) == "ab", "strip failed, got: %s", res.data.(string))
	remove(res)
	remove(sa)
	remove(sb)
}

@(test)
multiply_variants :: proc(t: ^testing.T) {
	a, _ := create_int(4)
	b, _ := create_int(3)
	res, code := multiply(a, b)
	testing.expectf(t, code == .OK && res.data.(int) == 12, "4*3 should be 12, got %d", res.data.(int))
	remove(res)
	remove(a)
	remove(b)

	sa, _ := create_string("ab")
	ib, _ := create_int(3)
	res, _ = multiply(sa, ib)
	testing.expectf(t, res.data.(string) == "ababab", "string multiply failed, got: %s", res.data.(string))
	remove(res)
	remove(sa)
	remove(ib)
}

@(test)
divide_int_int :: proc(t: ^testing.T) {
	a, _ := create_int(10)
	b, _ := create_int(4)
	res, code := divide(a, b)
	testing.expectf(t, code == .OK && res.data.(int) == 2, "10/4 should be 2, got %d", res.data.(int))
	remove(res)
	remove(a)
	remove(b)
}

@(test)
divide_by_zero_errors :: proc(t: ^testing.T) {
	a, _ := create_int(4)
	z, _ := create_int(0)
	res, code := divide(a, z)
	testing.expectf(t, res == nil && code == .DIVISION_BY_ZERO_A_INT_B_INT_IN_OBJECT_DIVIDE, "wrong code: %v", code)
	remove(a)
	remove(z)
}

@(test)
divide_nil_errors :: proc(t: ^testing.T) {
	a, _ := create_int(4)
	res, code := divide(nil, a)
	testing.expectf(t, res == nil && code == .OBJECT_IS_NIL_IN_OBJECT_DIVIDE, "wrong code: %v", code)
	remove(a)
}

@(test)
modulus_int_int :: proc(t: ^testing.T) {
	a, _ := create_int(10)
	b, _ := create_int(3)
	res, code := modulus(a, b)
	testing.expectf(t, code == .OK && res.data.(int) == 1, "10%3 should be 1, got %d", res.data.(int))
	remove(res)
	remove(a)
	remove(b)

	z, _ := create_int(0)
	res, code = modulus(a, z)
	testing.expectf(t, res == nil && code == .DIVISION_BY_ZERO_A_INT_B_INT_IN_OBJECT_MODULUS, "wrong code: %v", code)
	remove(z)
	remove(a)
}

@(test)
assign_copies_type_and_data :: proc(t: ^testing.T) {
	target, _ := create_int(1)
	source, _ := create_string("new")
	code := assign(target, source)
	testing.expectf(t, code == .OK, "assign failed: %v", code)
	testing.expectf(t, target.type == .STRING, "target type should update")
	testing.expectf(t, target.data.(string) == "new", "target data should update")
	remove(target)
	remove(source)
}

@(test)
assign_const_errors :: proc(t: ^testing.T) {
	target, _ := create_int(1)
	target.is_const = true
	source, _ := create_int(2)
	code := assign(target, source)
	testing.expectf(t, code == .CANNOT_ASSIGN_TO_CONSTANT_IN_OBJECT_ASSIGN, "wrong code: %v", code)
	remove(target)
	remove(source)
}

@(test)
assign_nil_errors :: proc(t: ^testing.T) {
	a, _ := create_int(1)
	code := assign(nil, a)
	testing.expectf(t, code == .OBJECT_IS_NIL_IN_OBJECT_ASSIGN, "wrong code: %v", code)
	remove(a)
}

@(test)
assign_retains_target_name :: proc(t: ^testing.T) {
	target, _ := create_int(1)
	target.name = "original"
	source, _ := create_int(2)
	code := assign(target, source)
	testing.expectf(t, code == .OK, "assign failed: %v", code)
	testing.expectf(t, target.name == "original", "target name should be retained, got: %s", target.name)
	remove(target)
	remove(source)
}

@(test)
assign_array_deep_copies :: proc(t: ^testing.T) {
	src, _ := create_array()
	one, _ := create_int(1)
	array_set(src, 0, one)
	target, _ := create_array()
	code := assign(target, src)
	testing.expectf(t, code == .OK, "assign failed: %v", code)
	got, _ := array_get(target, 0)
	testing.expectf(t, got != one, "deep copy should not share element references")
	testing.expectf(t, got.data.(int) == 1, "element value should match, got %d", got.data.(int))
	two, _ := create_int(2)
	assign(got, two)
	src_got, _ := array_get(src, 0)
	testing.expectf(t, src_got.data.(int) == 1, "source element should be independent, got %d", src_got.data.(int))
	remove(target)
	remove(src)
	remove(one)
	remove(two)
}

@(test)
assign_json_deep_copies :: proc(t: ^testing.T) {
	src, _ := from_json_string("{\"a\": 1}")
	target, _ := from_json_string("{}")
	code := assign(target, src)
	testing.expectf(t, code == .OK, "assign failed: %v", code)
	src_child, _ := json_get(src, "a")
	tgt_child, _ := json_get(target, "a")
	testing.expectf(t, tgt_child != src_child, "deep copy should not share json children")
	seven, _ := create_int(7)
	assign(tgt_child, seven)
	val, _ := get_numeric_value(src_child)
	testing.expectf(t, val == 1.0, "source child should be independent, got %v", val)
	remove(target)
	remove(src)
	remove(seven)
}

@(test)
int_len_digits :: proc(t: ^testing.T) {
	n, code := int_len(0)
	testing.expectf(t, code == .OK && n == 1, "int_len(0) should be 1, got %d", n)
	n, _ = int_len(123)
	testing.expectf(t, n == 3, "int_len(123) should be 3, got %d", n)
	n, _ = int_len(-45)
	testing.expectf(t, n == 2, "int_len(-45) should be 2, got %d", n)
}

@(test)
float_len_nonzero :: proc(t: ^testing.T) {
	n, _ := float_len(f32(12.5))
	testing.expectf(t, n > 0, "float_len should be positive, got %d", n)
}

@(test)
int_to_number_formats :: proc(t: ^testing.T) {
	s, code := int_to_number(42)
	testing.expectf(t, code == .OK && s == "42", "got: %s", s)
}

@(test)
float_to_number_formats :: proc(t: ^testing.T) {
	s, _ := float_to_number(f32(2.75))
	testing.expectf(t, s != "", "float_to_number should be nonempty")
}

@(test)
join_string_strings :: proc(t: ^testing.T) {
	a, _ := create_string("foo")
	b, _ := create_string("bar")
	res, code := join_string(a, b)
	testing.expectf(t, code == .OK && res.data.(string) == "foobar", "got: %s", res.data.(string))
	remove(res)
	remove(a)
	remove(b)
}

@(test)
join_string_int_prefix :: proc(t: ^testing.T) {
	a, _ := create_int(4)
	b, _ := create_string(" years")
	res, code := join_string(a, b)
	testing.expectf(t, code == .OK && res.data.(string) == "4 years", "got: %s", res.data.(string))
	remove(res)
	remove(a)
	remove(b)
}

@(test)
join_string_unsupported_errors :: proc(t: ^testing.T) {
	a, _ := create_bool(true)
	b, _ := create_string("x")
	res, code := join_string(a, b)
	testing.expectf(t, res == nil && code == .FAILED_TO_CONCAT_STRING_OBJECT_A_IN_OBJECT_STRING_JOIN_STRING, "wrong code: %v", code)
	remove(a)
	remove(b)
}

@(test)
position_of_first_instance_found :: proc(t: ^testing.T) {
	o, _ := create_string("banana")
	pos, code := position_of_first_instance(o, "na")
	testing.expectf(t, code == .OK && pos == 2, "first 'na' should be at 2, got %d", pos)
	remove(o)
}

@(test)
position_of_first_instance_missing :: proc(t: ^testing.T) {
	o, _ := create_string("banana")
	pos, code := position_of_first_instance(o, "z")
	testing.expectf(t, code == .OK && pos == -1, "missing should be -1, got %d", pos)
	remove(o)
}

@(test)
position_of_first_instance_errors :: proc(t: ^testing.T) {
	pos, code := position_of_first_instance(nil, "a")
	testing.expectf(t, pos == -1 && code == .OBJECT_IS_NIL_IN_OBJECT_STRING_POSITION_OF_FIST_INSTANCE, "wrong code: %v", code)

	io, _ := create_int(1)
	pos, code = position_of_first_instance(io, "a")
	testing.expectf(t, pos == -1 && code == .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_POSITION_OF_FIRST_INSTANCE, "wrong code: %v", code)
	remove(io)
}

@(test)
position_of_last_instance_found :: proc(t: ^testing.T) {
	o, _ := create_string("banana")
	pos, code := position_of_last_instance(o, "na")
	testing.expectf(t, code == .OK && pos == 4, "last 'na' should be at 4, got %d", pos)
	remove(o)
}

@(test)
substring_basic :: proc(t: ^testing.T) {
	o, _ := create_string("hello")
	res, code := substring(o, 1, 3)
	testing.expectf(t, code == .OK && res.data.(string) == "ell", "got: %s", res.data.(string))
	remove(res)
	remove(o)
}

@(test)
substring_to_end_with_minus_one :: proc(t: ^testing.T) {
	o, _ := create_string("hello")
	res, _ := substring(o, 1, -1)
	testing.expectf(t, res.data.(string) == "ello", "got: %s", res.data.(string))
	remove(res)
	remove(o)
}

@(test)
substring_out_of_bounds_errors :: proc(t: ^testing.T) {
	o, _ := create_string("hello")
	res, code := substring(o, 10, 1)
	testing.expectf(t, res == nil && code == .SUBSTRING_START_OUT_OF_BOUNDS_IN_OBJECT_STRING_SUBSTRING, "wrong code: %v", code)
	remove(o)
}

@(test)
strip_instances_from_string_basic :: proc(t: ^testing.T) {
	target, _ := create_string("a1b1c")
	inst, _ := create_string("1")
	res, code := strip_instances_from_string(target, inst)
	testing.expectf(t, code == .OK && res.data.(string) == "abc", "got: %s", res.data.(string))
	remove(res)
	remove(target)
	remove(inst)
}

@(test)
strip_instances_non_string_errors :: proc(t: ^testing.T) {
	target, _ := create_int(1)
	inst, _ := create_string("1")
	res, code := strip_instances_from_string(target, inst)
	testing.expectf(t, res == nil && code == .STRING_OPERATION_ON_NON_STRING_OBJECT_IN_OBJECT_STRING_STRIP_INSTANCE_FROM_STRING, "wrong code: %v", code)
	remove(target)
	remove(inst)
}

@(test)
lengthen_string_repeats :: proc(t: ^testing.T) {
	target, _ := create_string("ab")
	len, _ := create_int(2)
	res, code := lengthen_string(target, len)
	testing.expectf(t, code == .OK && res.data.(string) == "abab", "got: %s", res.data.(string))
	remove(res)
	remove(target)
	remove(len)
}

@(test)
shorten_string_truncates :: proc(t: ^testing.T) {
	target, _ := create_string("hello")
	len, _ := create_int(2)
	res, code := shorten_string(target, len)
	testing.expectf(t, code == .OK && res.data.(string) == "hel", "got: %s", res.data.(string))
	remove(res)
	remove(target)
	remove(len)
}

@(test)
multiply_string_variants :: proc(t: ^testing.T) {
	target, _ := create_string("ab")
	mul, _ := create_int(2)
	res, code := multiply_string(target, mul)
	testing.expectf(t, code == .OK && res.data.(string) == "abab", "got: %s", res.data.(string))
	remove(res)

	zero, _ := create_int(0)
	res, _ = multiply_string(target, zero)
	testing.expectf(t, res.data.(string) == "", "zero multiplier should give empty")
	remove(res)

	neg, _ := create_int(-1)
	res, code = multiply_string(target, neg)
	testing.expectf(t, res == nil && code == .INVALID_MULTIPLIER_IN_OBJECT_STRING_MULTIPLY_STRING, "wrong code: %v", code)
	remove(mul)
	remove(target)
	remove(zero)
	remove(neg)
}

@(test)
divide_string_truncates :: proc(t: ^testing.T) {
	target, _ := create_string("hello")
	div, _ := create_int(2)
	res, code := divide_string(target, div)
	testing.expectf(t, code == .OK && res.data.(string) == "he", "got: %s", res.data.(string))
	remove(res)
	remove(target)
	remove(div)
}

@(test)
modulus_string_tail :: proc(t: ^testing.T) {
	target, _ := create_string("hello")
	mod, _ := create_int(3)
	res, code := modulus_string(target, mod)
	testing.expectf(t, code == .OK && res.data.(string) == "lo", "got: %s", res.data.(string))
	remove(res)
	remove(target)
	remove(mod)
}

@(test)
modulus_string_zero_errors :: proc(t: ^testing.T) {
	target, _ := create_string("hello")
	zero, _ := create_int(0)
	res, code := modulus_string(target, zero)
	testing.expectf(t, res == nil && code == .DIVISION_BY_ZERO_IN_OBJECT_STRING_MODULUS_STRING, "wrong code: %v", code)
	remove(target)
	remove(zero)
}

@(test)
from_json_string_parses :: proc(t: ^testing.T) {
	o, code := from_json_string("{\"a\": 1}")
	testing.expectf(t, code == .OK, "from_json_string failed: %v", code)
	testing.expectf(t, o.type == .JSON, "type should be JSON")
	remove(o)
}

@(test)
from_json_string_invalid_errors :: proc(t: ^testing.T) {
	o, code := from_json_string("nope")
	testing.expectf(t, o == nil && code == .OBJECT_IS_NIL_IN_FROM_JSON_STRING, "wrong code: %v", code)
}

@(test)
json_get_finds_key :: proc(t: ^testing.T) {
	o, _ := from_json_string("{\"a\": 5}")
	got, code := json_get(o, "a")
	testing.expectf(t, code == .OK, "json_get failed: %v", code)
	val, ok := get_numeric_value(got)
	testing.expectf(t, ok && val == 5.0, "value of 'a' should be 5, got %v", val)
	remove(o)
}

@(test)
json_get_missing_creates_key :: proc(t: ^testing.T) {
	o, _ := from_json_string("{\"a\": 5}")
	got, code := json_get(o, "missing")
	testing.expectf(t, code == .OK, "json_get missing failed: %v", code)
	testing.expectf(t, got != nil && got.name == "missing", "should create a key")
	remove(o)
}

@(test)
json_get_nil_errors :: proc(t: ^testing.T) {
	got, code := json_get(nil, "a")
	testing.expectf(t, got == nil && code == .OBJECT_IS_NIL_IN_JSON_GET, "wrong code: %v", code)
}

@(test)
to_json_string_int :: proc(t: ^testing.T) {
	o, _ := create_int(42)
	s, code := to_json_string(o)
	testing.expectf(t, code == .OK && s == "42", "got: %s", s)
	remove(o)
}

@(test)
to_json_string_nil_errors :: proc(t: ^testing.T) {
	s, code := to_json_string(nil)
	testing.expectf(t, s == "" && code == .OBJECT_IS_NIL_IN_TO_JSON_STRING, "wrong code: %v", code)
}

@(test)
create_http_body_valid_json :: proc(t: ^testing.T) {
	o, code := create_http_body("{\"k\": 1}")
	testing.expectf(t, code == .OK, "create_http_body failed: %v", code)
	testing.expectf(t, o.type == .JSON, "valid body should parse to JSON")
	testing.expectf(t, o.name == "body", "name should be 'body'")
	remove(o)
}

@(test)
create_http_body_invalid_becomes_string :: proc(t: ^testing.T) {
	o, code := create_http_body("raw text")
	testing.expectf(t, code == .OK, "create_http_body failed: %v", code)
	testing.expectf(t, o.type == .STRING, "invalid body should fall back to STRING")
	remove(o)
}

@(test)
create_http_head_parses_code :: proc(t: ^testing.T) {
	o, code := create_http_head("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n")
	testing.expectf(t, code == .OK, "create_http_head failed: %v", code)
	testing.expectf(t, o.type == .JSON, "head should be JSON")
	remove(o)
}

@(test)
create_http_response_aggregates :: proc(t: ^testing.T) {
	o, code := create_http_response("{\"b\": 1}", "HTTP/1.1 200 OK\r\n\r\n")
	testing.expectf(t, code == .OK, "create_http_response failed: %v", code)
	testing.expectf(t, o.type == .JSON, "response should be JSON")
	testing.expectf(t, len(o.data.(types.object_json_t).value) == 2, "should hold body and head")
	remove(o)
}