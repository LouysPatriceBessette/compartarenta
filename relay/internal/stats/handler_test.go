package stats

import (
	"testing"
)

func TestSuppressSmallCountryBuckets(t *testing.T) {
	in := map[string]int64{
		"FR":           12,
		"US":           3,
		"UNDISCLOSED":  5,
		"DE":           9,
	}
	got := SuppressSmallCountryBuckets(in)
	if got["FR"] != 12 {
		t.Fatalf("FR want 12 got %d", got["FR"])
	}
	if got["UNDISCLOSED"] != 5 {
		t.Fatalf("UNDISCLOSED want 5 got %d", got["UNDISCLOSED"])
	}
	// US (3) + DE (9) = 12 -> OTHER
	if got["OTHER"] != 12 {
		t.Fatalf("OTHER want 12 got %d", got["OTHER"])
	}
	if _, ok := got["US"]; ok {
		t.Fatal("US should be suppressed")
	}
}

func TestSuppressSmallCountryBucketsBoundary(t *testing.T) {
	in := map[string]int64{"XX": 10}
	got := SuppressSmallCountryBuckets(in)
	if got["XX"] != 10 {
		t.Fatalf("exactly threshold: want 10 got %d", got["XX"])
	}
	if _, ok := got["OTHER"]; ok {
		t.Fatal("OTHER should be absent")
	}
}
