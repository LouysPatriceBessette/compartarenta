// Command relay is the Compartarenta relay server entry point.
//
// The process binds two listeners:
//   - PublicListenAddr: the relay protocol + /healthz + /readyz.
//   - PrivateListenAddr: /metrics. The deployment manifest does not
//     publish this port to the public internet.
//
// On startup the relay:
//   1. Loads configuration from env vars (no secrets in source).
//   2. Connects to PostgreSQL and applies any pending migrations.
//   3. Verifies the on-disk schema version matches the binary's expected
//      version; otherwise it refuses to start
//      (`relay-state-schema-and-retention` /
//      "Schema migrations are versioned and reviewable").
//   4. Starts the periodic sweeper that enforces TTL-based deletion.
//   5. Serves HTTP until SIGTERM/SIGINT, then drains in-flight requests
//      up to ShutdownTimeout.
package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus/promhttp"

	"github.com/compartarenta/relay/internal/api"
	"github.com/compartarenta/relay/internal/config"
	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/metrics"
	"github.com/compartarenta/relay/internal/store"
	"github.com/compartarenta/relay/internal/sweeper"
	"github.com/compartarenta/relay/internal/version"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	logger := logging.New()
	ctx, cancel := signal.NotifyContext(context.Background(),
		os.Interrupt, syscall.SIGTERM)
	defer cancel()

	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("config: %w", err)
	}

	connectCtx, connectCancel := context.WithTimeout(ctx, 30*time.Second)
	defer connectCancel()
	st, err := store.New(connectCtx, cfg.DatabaseURL)
	if err != nil {
		return fmt.Errorf("store: %w", err)
	}
	defer st.Close()

	logger.Info(ctx, "relay.start",
		logging.F(logging.KeyBuild, version.Build),
		logging.F(logging.KeySchemaVersion, version.Expected),
	)

	srv := api.NewServer(cfg, st, logger)
	sw := sweeper.New(cfg, st, logger)
	go sw.Loop(ctx)

	publicServer := &http.Server{
		Addr:              cfg.PublicListenAddr,
		Handler:           srv.PublicHandler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	privateMux := http.NewServeMux()
	privateMux.Handle("/metrics", promhttp.HandlerFor(metrics.Registry(),
		promhttp.HandlerOpts{}))
	privateServer := &http.Server{
		Addr:              cfg.PrivateListenAddr,
		Handler:           privateMux,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
	}

	errCh := make(chan error, 2)
	go func() {
		logger.Info(ctx, "listener.public",
			logging.F(logging.KeyAddr, publicServer.Addr))
		errCh <- publicServer.ListenAndServe()
	}()
	go func() {
		logger.Info(ctx, "listener.private",
			logging.F(logging.KeyAddr, privateServer.Addr))
		errCh <- privateServer.ListenAndServe()
	}()

	select {
	case <-ctx.Done():
		logger.Info(ctx, "relay.shutdown_signal")
	case err := <-errCh:
		if !errors.Is(err, http.ErrServerClosed) {
			logger.Error(ctx, "listener.failed",
				logging.F(logging.KeyError, err.Error()))
		}
	}

	shutdownCtx, shutdownCancel := context.WithTimeout(
		context.Background(), cfg.ShutdownTimeout)
	defer shutdownCancel()
	_ = publicServer.Shutdown(shutdownCtx)
	_ = privateServer.Shutdown(shutdownCtx)
	return nil
}
