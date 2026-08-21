package http

import "../types"
import "base:runtime"
import "core:c"
import "core:strings"
import "vendor:curl"

do_request :: proc(
	method: string,
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	handle := curl.easy_init()
	if handle == nil do return "", "", .HANDLE_IS_NIL_IN_DO_REQUEST
	defer curl.easy_cleanup(handle)
	body_builder, header_builder: strings.Builder
	strings.builder_init(&body_builder, context.temp_allocator)
	strings.builder_init(&header_builder, context.temp_allocator)
	c_url := strings.clone_to_cstring(url, context.temp_allocator)
	curl.easy_setopt(handle, .URL, c_url)
	curl.easy_setopt(handle, .CONNECTTIMEOUT, c.long(10))
	curl.easy_setopt(handle, .TIMEOUT, c.long(30))
	curl.easy_setopt(handle, .FOLLOWLOCATION, c.long(1))
	curl.easy_setopt(handle, .NOSIGNAL, c.long(1))
	curl.easy_setopt(handle, .WRITEFUNCTION, write_callback)
	curl.easy_setopt(handle, .WRITEDATA, &body_builder)
	curl.easy_setopt(handle, .HEADERFUNCTION, header_callback)
	curl.easy_setopt(handle, .HEADERDATA, &header_builder)
	switch method {
	case "GET":
		curl.easy_setopt(handle, .HTTPGET, c.long(1))
	case "POST":
		curl.easy_setopt(handle, .POST, c.long(1))
	case "HEAD":
		curl.easy_setopt(handle, .NOBODY, c.long(1))
	case "PUT", "PATCH", "DELETE":
		c_method := strings.clone_to_cstring(method, context.temp_allocator)
		curl.easy_setopt(handle, .CUSTOMREQUEST, c_method)
	case:
		c_method := strings.clone_to_cstring(method, context.temp_allocator)
		curl.easy_setopt(handle, .CUSTOMREQUEST, c_method)
	}
	body_len := len(body)
	if body_len > 0 {
		c_body := strings.clone_to_cstring(body, context.temp_allocator)
		curl.easy_setopt(handle, .POSTFIELDS, c_body)
		curl.easy_setopt(handle, .POSTFIELDSIZE, c.long(body_len))
	} else if method == "POST" || method == "PUT" || method == "PATCH" {
		curl.easy_setopt(handle, .POSTFIELDS, "")
		curl.easy_setopt(handle, .POSTFIELDSIZE, c.long(0))
	}
	header_list := parse_header_list(json_headers)
	if method == "POST" || method == "PUT" || method == "PATCH" {
		c_expect := strings.clone_to_cstring("Expect:", context.temp_allocator)
		header_list = curl.slist_append(header_list, c_expect)
	}
	if header_list != nil {
		curl.easy_setopt(handle, .HTTPHEADER, header_list)
	}
	defer if header_list != nil do curl.slist_free_all(header_list)
	res := curl.easy_perform(handle)
	if res != .E_OK do return "", "", .FAILED_CURL_REQUEST

	return strings.to_string(body_builder), strings.to_string(header_builder), .OK
}

header_callback :: proc "c" (ptr: rawptr, size, nmemb: uint, userdata: rawptr) -> c.size_t {
	context = runtime.default_context()
	total_size := size * nmemb
	if ptr == nil || userdata == nil || total_size == 0 do return c.size_t(total_size)

	builder := (^strings.Builder)(userdata)
	bytes := ([^]u8)(ptr)[:total_size]
	strings.write_bytes(builder, bytes)

	return c.size_t(total_size)
}

write_callback :: proc "c" (ptr: rawptr, size, nmemb: uint, userdata: rawptr) -> c.size_t {
	context = runtime.default_context()
	total_size := size * nmemb
	if ptr == nil || userdata == nil || total_size == 0 do return c.size_t(total_size)

	builder := (^strings.Builder)(userdata)
	bytes := ([^]u8)(ptr)[:total_size]
	strings.write_bytes(builder, bytes)

	return c.size_t(total_size)
}
