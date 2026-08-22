package http

import "../types"


get :: proc(
	url: string,
	json_headers: string = "",
) -> (
	_body: string,
	_head: string,
	code: types.exit_codes,
) {
	_body, _head = do_request("GET", url, json_headers) or_return
	return
}
