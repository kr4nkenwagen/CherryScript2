package http

import "../types"
import "core:strings"
import "vendor:curl"

write_callback :: proc "c" (ptr: rawptr, size, nmemb: uint, userdata: rawptr) -> uint {
	total_size := size * nmemb
	builder := (^strings.Builder)(userdata)
	bytes := ([^]u8)(ptr)[:total_size]
	context = context
	strings.write_bytes(builder, bytes)
	return total_size
}

get :: proc(url: string) -> (string, types.exit_codes) {
	handle := curl.easy_init()
	if handle == nil do return "", .HANDLE_IS_NIL_IN_HTTP_GET
	defer curl.easy_cleanup(handle)
	builder: strings.Builder
	strings.builder_init(&builder)
	c_url := strings.clone_to_cstring(url, context.temp_allocator)
	curl.easy_setopt(handle, .URL, c_url)
	curl.easy_setopt(handle, .WRITEFUNCTION, write_callback)
	curl.easy_setopt(handle, .WRITEDATA, &builder)
	curl.easy_setopt(handle, .FOLLOWLOCATION, i64(1)) // Follow HTTP 3xx redirects
	res := curl.easy_perform(handle)
	if res != .E_OK {
		strings.builder_destroy(&builder)
		return "", .FAILED_TO_BUILD_RETURN_VALUE_AS_STRING_IN_HTTP_GET
	}
	return strings.to_string(builder), .OK
}
