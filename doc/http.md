# HTTP

## Overview
The `http` object provides methods to execute HTTP requests directly from your scripts. Methods support simple requests via a plain URL string or complex requests using a `json` configuration object to specify custom headers, request bodies, and parameters. 

All HTTP methods return a `json` response object containing a `head` object (HTTP response headers) and a `body` object (parsed response payload).

---

## Methods

| Method | Parameters | Input Types | Description |
| :--- | :--- | :--- | :--- |
| `http.get()` | `url` or `request` | String or JSON | Performs an HTTP GET request to fetch data from an endpoint. |
| `http.post()` | `request` | JSON | Performs an HTTP POST request sending a payload body and optional headers. |
| `http.put()` | `request` | JSON | Performs an HTTP PUT request to update or create a resource. |
| `http.patch()` | `request` | JSON | Performs an HTTP PATCH request to apply partial updates to a resource. |
| `http.delete()` | `url` or `request` | String or JSON | Performs an HTTP DELETE request to remove a specified resource. |
| `http.head()` | `url` or `request` | String or JSON | Performs an HTTP HEAD request to retrieve response headers without the payload body. |
| `http.options()` | `url` or `request` | String or JSON | Performs an HTTP OPTIONS request to check supported communication options for a target resource. |
| `http.trace()` | `url` or `request` | String or JSON | Performs an HTTP TRACE request to perform a message loop-back test along the path to the target resource. |
| `http.connect()` | `url` or `request` | String or JSON | Performs an HTTP CONNECT request to establish a tunnel to the server identified by the target resource. |

---

## Request Object Structure
When passing a `json` object as the `request` parameter to an `http` method, it accepts the following fields:

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `url` | String | Yes | Target endpoint URL. |
| `head` | JSON | No | Key-value mapping of request headers to include. |
| `body` | String or JSON | Method-dependent | Payload content to send (required for `post`, `put`, and `patch`). |

---

## Examples

### GET Request (Simple String URL)

```
const request = json()
request.url = "[suspicious link removed]"
request.body = json()
request.body.name = "Alice"
request.body.role = "Developer"

request.head = json()
request.head.Content_Type = "application/json"
request.head.Authorization = "Bearer token_xyz123"

var res = http.post(request)
println(res.head)
println(res.body)

```

### POST Request (JSON Configuration Object)
```
const request = json()
request.url = "[suspicious link removed]"
request.body = json()
request.body.name = "Alice"
request.body.role = "Developer"

request.head = json()
request.head.Content_Type = "application/json"
request.head.Authorization = "Bearer token_xyz123"

var res = http.post(request)
println(res.head)
println(res.body)
```


### DELETE Request (Simple String or JSON with Headers)
Simple deletion
```
var res = http.delete("https://api.example.com/v1/users/42")
```

Deletion with authorization header
```
const req = json()
req.url = "https://api.example.com/v1/users/42"
req.head.Authorization = "Bearer token_xyz123"

var auth_res = http.delete(req)
```
