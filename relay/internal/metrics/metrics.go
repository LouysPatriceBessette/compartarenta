// Package metrics exposes Prometheus metrics. The collectors are
// registered into a private registry so the public listener never serves
// /metrics; the private listener serves it on a private network only
// (`relay-observability-without-plaintext` / "The metrics endpoint is
// not publicly reachable").
package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
)

// Registry returns the Prometheus registry for the relay. Default Go
// process collectors are included so the operator can monitor CPU/RAM.
func Registry() *prometheus.Registry {
	registry.MustRegister(collectors.NewGoCollector())
	registry.MustRegister(collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}))
	return registry
}

var registry = prometheus.NewRegistry()

// Counters and histograms. Each is registered once at package init so the
// /metrics endpoint sees them even before the first request lands.

var (
	HTTPRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "relay",
			Subsystem: "http",
			Name:      "requests_total",
			Help:      "Number of HTTP requests served, labeled by endpoint and status class.",
		},
		[]string{"endpoint", "status_class"},
	)

	HTTPLatencySeconds = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace: "relay",
			Subsystem: "http",
			Name:      "request_duration_seconds",
			Help:      "End-to-end request latency.",
			Buckets:   prometheus.ExponentialBuckets(0.001, 2, 12),
		},
		[]string{"endpoint"},
	)

	HTTPRejections = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "relay",
			Subsystem: "http",
			Name:      "rejections_total",
			Help:      "Requests rejected by the relay before any state was written.",
		},
		[]string{"endpoint", "reason"},
	)

	EnvelopesAccepted = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "envelopes",
		Name:      "accepted_total",
		Help:      "Envelopes accepted into the queue.",
	})

	EnvelopesDelivered = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "envelopes",
		Name:      "delivered_total",
		Help:      "Envelopes ack'd by their recipient and deleted from the queue.",
	})

	EnvelopesExpired = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "envelopes",
		Name:      "expired_total",
		Help:      "Envelopes deleted by the sweeper after TTL expiry.",
	})

	IdempotencyExpired = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "idempotency",
		Name:      "expired_total",
		Help:      "Idempotency entries deleted by the sweeper after TTL expiry.",
	})

	RoutingCreated = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "routing",
		Name:      "created_total",
		Help:      "Routing relationships established.",
	})

	RoutingSevered = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "routing",
		Name:      "severed_total",
		Help:      "Routing relationships removed (disconnect, inactivity, or operator action).",
	})

	SweeperRuns = prometheus.NewCounter(prometheus.CounterOpts{
		Namespace: "relay",
		Subsystem: "sweeper",
		Name:      "runs_total",
		Help:      "Sweeper invocations.",
	})

	SweeperRunDuration = prometheus.NewHistogram(prometheus.HistogramOpts{
		Namespace: "relay",
		Subsystem: "sweeper",
		Name:      "run_duration_seconds",
		Help:      "Time taken by each sweeper run.",
		Buckets:   prometheus.ExponentialBuckets(0.001, 2, 12),
	})

	QueueDepth = prometheus.NewGauge(prometheus.GaugeOpts{
		Namespace: "relay",
		Subsystem: "envelopes",
		Name:      "queue_depth",
		Help:      "Number of undelivered envelopes currently stored.",
	})

	OldestUndeliveredSeconds = prometheus.NewGauge(prometheus.GaugeOpts{
		Namespace: "relay",
		Subsystem: "envelopes",
		Name:      "oldest_undelivered_age_seconds",
		Help:      "Age of the oldest undelivered envelope.",
	})

	RateLimitRejections = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: "relay",
			Subsystem: "ratelimit",
			Name:      "rejections_total",
			Help:      "Requests rejected by the rate limiter.",
		},
		[]string{"scope"},
	)
)

func init() {
	registry.MustRegister(
		HTTPRequests, HTTPLatencySeconds, HTTPRejections,
		EnvelopesAccepted, EnvelopesDelivered, EnvelopesExpired,
		IdempotencyExpired, RoutingCreated, RoutingSevered,
		SweeperRuns, SweeperRunDuration,
		QueueDepth, OldestUndeliveredSeconds, RateLimitRejections,
	)
}
