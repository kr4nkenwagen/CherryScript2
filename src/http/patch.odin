package http

import "../types"

patch :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("PATCH", url, json_headers, body)
}
