package http

import "../types"

delete :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	_body: string,
	_head: string,
	code: types.exit_codes,
) {
	_body, _head = do_request("DELETE", url, json_headers, body) or_return
	return
}
