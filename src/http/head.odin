package http

import "../types"

head :: proc(url: string, json_headers: string = "") -> (string, string, types.exit_codes) {
	return do_request("HEAD", url, json_headers)
}
