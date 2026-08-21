package http

import "../types"

options :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("OPTIONS", url, json_headers, body)
}
