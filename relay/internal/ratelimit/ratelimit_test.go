package ratelimit

import (
	"testing"
	"time"
)

func TestAllowConsumesTokensAndRefills(t *testing.T) {
	lim := New(10) // 10 tokens/sec, burst 40
	now := time.Unix(0, 0)
	lim.SetClock(func() time.Time { return now })

	for i := 0; i < 40; i++ {
		if !lim.Allow("alice") {
			t.Fatalf("burst should accept the first 40, denied at %d", i)
		}
	}
	if lim.Allow("alice") {
		t.Fatalf("41st request should be rate-limited")
	}

	now = now.Add(2 * time.Second)
	if !lim.Allow("alice") {
		t.Fatalf("after 2 seconds at 10 tokens/sec, alice should have tokens again")
	}
}

func TestScopesAreIndependent(t *testing.T) {
	lim := New(1) // burst 4
	now := time.Unix(0, 0)
	lim.SetClock(func() time.Time { return now })

	for i := 0; i < 4; i++ {
		if !lim.Allow("alice") {
			t.Fatalf("alice burst denied at %d", i)
		}
	}
	if !lim.Allow("bob") {
		t.Fatalf("bob's bucket is independent; should still allow first request")
	}
	if lim.Allow("alice") {
		t.Fatalf("alice exhausted; further allow should be false")
	}
}

func TestIdleBucketsAreEvicted(t *testing.T) {
	lim := New(10)
	t0 := time.Unix(0, 0)
	lim.SetClock(func() time.Time { return t0 })
	lim.Allow("scope-a")
	if got := lim.Size(); got != 1 {
		t.Fatalf("expected 1 bucket, got %d", got)
	}

	t1 := t0.Add(20 * time.Minute)
	lim.SetClock(func() time.Time { return t1 })
	lim.Allow("scope-b") // arrival triggers eviction sweep

	if got := lim.Size(); got != 1 {
		t.Fatalf("expected scope-a to be evicted, leaving only scope-b; got size=%d", got)
	}
}
