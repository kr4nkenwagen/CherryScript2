package http

import "../types"

delete :: proc(
	url: string,
	json_headers: string = "",
	body: string = "",
) -> (
	string,
	string,
	types.exit_codes,
) {
	return do_request("DELETE", url, json_headers, body)
}
