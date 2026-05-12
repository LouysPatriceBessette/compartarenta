// Package ratelimit implements a token-bucket limiter keyed by opaque
// scope strings (per opaque identity, per source IP). Buckets evict
// themselves after a documented idle window so the in-memory map cannot
// grow without bound.
//
// The limiter never inspects ciphertext or any payload field. Scopes are
// hex-encoded opaque bytes (identity) or string IPs.
package ratelimit

import (
	"sync"
	"time"
)

// Limiter is a token-bucket limiter. Safe for concurrent use.
type Limiter struct {
	mu        sync.Mutex
	buckets   map[string]*bucket
	rate      float64       // tokens per second
	burst     float64       // bucket size
	idleEvict time.Duration // an idle bucket older than this is removed
	now       func() time.Time
}

type bucket struct {
	tokens     float64
	lastRefill time.Time
}

// New builds a Limiter with `rate` tokens/sec and a burst capacity of
// max(4*rate, 1). The bucket store evicts idle buckets after 10 minutes.
func New(rate float64) *Limiter {
	burst := 4 * rate
	if burst < 1 {
		burst = 1
	}
	return &Limiter{
		buckets:   map[string]*bucket{},
		rate:      rate,
		burst:     burst,
		idleEvict: 10 * time.Minute,
		now:       time.Now,
	}
}

// SetClock replaces the wall-clock source. Tests only.
func (l *Limiter) SetClock(now func() time.Time) {
	l.mu.Lock()
	defer l.mu.Unlock()
	l.now = now
}

// Allow consumes one token from `scope`. Returns true when the request is
// within the rate, false when the limiter is exhausted for this scope.
func (l *Limiter) Allow(scope string) bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := l.now()
	b, ok := l.buckets[scope]
	if !ok {
		b = &bucket{tokens: l.burst - 1, lastRefill: now}
		l.buckets[scope] = b
		l.evictIdleLocked(now)
		return true
	}
	elapsed := now.Sub(b.lastRefill).Seconds()
	if elapsed > 0 {
		b.tokens += elapsed * l.rate
		if b.tokens > l.burst {
			b.tokens = l.burst
		}
		b.lastRefill = now
	}
	if b.tokens < 1 {
		return false
	}
	b.tokens--
	l.evictIdleLocked(now)
	return true
}

// Size returns the current number of live buckets. Used by tests to
// confirm eviction behavior.
func (l *Limiter) Size() int {
	l.mu.Lock()
	defer l.mu.Unlock()
	return len(l.buckets)
}

func (l *Limiter) evictIdleLocked(now time.Time) {
	for k, b := range l.buckets {
		if now.Sub(b.lastRefill) > l.idleEvict {
			delete(l.buckets, k)
		}
	}
}
