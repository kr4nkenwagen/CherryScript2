package http

import "../types"

head :: proc(
	url: string,
	json_headers: string = "",
) -> (
	_body: string,
	_head: string,
	code: types.exit_codes,
) {
	_body, _head = do_request("HEAD", url, json_headers) or_return
	return
}
