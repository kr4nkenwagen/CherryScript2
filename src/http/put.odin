package http

import "../types"

put :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("PUT", url, json_headers, body)
}
