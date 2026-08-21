package http

import "../types"


post :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("POST", url, json_headers, body)
}
