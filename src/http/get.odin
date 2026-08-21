package http

import "../types"


get :: proc(url: string, json_headers: string = "") -> (string, string, types.exit_codes) {
	return do_request("GET", url, json_headers)
}
