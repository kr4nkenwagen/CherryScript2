package http

import "../types"

connect :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("CONNECT", url, json_headers, body)
}
