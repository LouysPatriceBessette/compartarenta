package api

import (
	"net/http"
	"net/http/httptest"
)

// newRequest is a tiny helper for tests that need an *http.Request
// without spinning up a server.
func newRequest(method, path string) *http.Request {
	r := httptest.NewRequest(method, path, nil)
	return r
}
