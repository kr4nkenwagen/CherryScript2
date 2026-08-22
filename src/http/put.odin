package http

import "../types"

put :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	_body: string,
	_head: string,
	code: types.exit_codes,
) {
	_body, _head = do_request("PUT", url, json_headers, body) or_return
	return
}
