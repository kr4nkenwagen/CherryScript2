package http

import "../types"

connect :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	_head: string,
	_body: string,
	code: types.exit_codes,
) {
	_body, _head = do_request("CONNECT", url, json_headers, body) or_return
	return
}
