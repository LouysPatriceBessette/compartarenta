package stats

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestIsLoopbackRemote(t *testing.T) {
	cases := []struct {
		remote string
		want   bool
	}{
		{"127.0.0.1:9091", true},
		{"[::1]:9091", true},
		{"10.0.0.5:9091", false},
		{"203.0.113.1:443", false},
	}
	for _, c := range cases {
		r := httptest.NewRequest(http.MethodGet, "/", nil)
		r.RemoteAddr = c.remote
		if got := IsLoopbackRemote(r); got != c.want {
			t.Fatalf("RemoteAddr %q: got %v want %v", c.remote, got, c.want)
		}
	}
}

func TestHandlerRejectsNonLoopback(t *testing.T) {
	h := Handler(nil, func() time.Time { return time.Now() })
	r := httptest.NewRequest(http.MethodGet, "/internal/stats/daily", nil)
	r.RemoteAddr = "192.168.1.1:9091"
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusNotFound {
		t.Fatalf("status %d want 404", w.Code)
	}
}

func TestHandlerRejectsNonGet(t *testing.T) {
	h := Handler(nil, func() time.Time { return time.Now() })
	r := httptest.NewRequest(http.MethodPost, "/internal/stats/daily", nil)
	r.RemoteAddr = "127.0.0.1:9091"
	w := httptest.NewRecorder()
	h.ServeHTTP(w, r)
	if w.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status %d want 405", w.Code)
	}
}

func TestSuppressSmallCountryBucketsZeroAndNine(t *testing.T) {
	in := map[string]int64{"AA": 0, "BB": 9}
	got := SuppressSmallCountryBuckets(in)
	if got["OTHER"] != 9 {
		t.Fatalf("OTHER want 9 got %d", got["OTHER"])
	}
}

func TestSuppressSmallCountryBucketsTenAndEleven(t *testing.T) {
	in := map[string]int64{"CA": 10, "US": 11, "XX": 9}
	got := SuppressSmallCountryBuckets(in)
	if got["CA"] != 10 {
		t.Fatalf("CA want 10 got %d", got["CA"])
	}
	if got["US"] != 11 {
		t.Fatalf("US want 11 got %d", got["US"])
	}
	if got["OTHER"] != 9 {
		t.Fatalf("OTHER want 9 got %d", got["OTHER"])
	}
}

func TestSuppressSmallCountryBucketsUndisclosedNeverMerged(t *testing.T) {
	in := map[string]int64{"UNDISCLOSED": 3, "AA": 2}
	got := SuppressSmallCountryBuckets(in)
	if got["UNDISCLOSED"] != 3 {
		t.Fatalf("UNDISCLOSED want 3 got %d", got["UNDISCLOSED"])
	}
	if got["OTHER"] != 2 {
		t.Fatalf("OTHER want 2 got %d", got["OTHER"])
	}
}
