package http

import "../types"

trace :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("TRACE", url, json_headers, body)
}
