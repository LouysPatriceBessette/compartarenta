package store

import "testing"

func TestNormalizeCountryCode(t *testing.T) {
	cases := []struct {
		in   string
		want string
	}{
		{"", "UNDISCLOSED"},
		{"  ", "UNDISCLOSED"},
		{"UNDISCLOSED", "UNDISCLOSED"},
		{"undisclosed", "UNDISCLOSED"},
		{"ca", "CA"},
		{"FR", "FR"},
		{" us ", "US"},
		{"CAN", "UNDISCLOSED"},
		{"C1", "UNDISCLOSED"},
		{"XX", "XX"},
	}
	for _, c := range cases {
		t.Run(c.in, func(t *testing.T) {
			if got := NormalizeCountryCode(c.in); got != c.want {
				t.Fatalf("NormalizeCountryCode(%q) = %q, want %q", c.in, got, c.want)
			}
		})
	}
}
