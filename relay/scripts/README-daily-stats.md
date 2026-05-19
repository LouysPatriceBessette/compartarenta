# Daily relay statistics file

The relay exposes `GET http://127.0.0.1:9091/internal/stats/daily?date=YYYY-MM-DD` (bind address overridden by `STATS_LISTEN_ADDR`, or disabled with `STATS_LISTEN_ADDR=-`). Only loopback callers receive data; any other remote address gets HTTP 404.

The operator should run `scripts/daily-stats-append.sh` from cron (example: `7 0 * * *` for 00:07 UTC) under the same UNIX user as the relay process. The script:

1. Calls the stats endpoint for **yesterday** in UTC.
2. Appends one JSON object as a single line to `STATS_FILE_PATH` (default `/srv/compartarenta-stats/daily.jsonl`). The variable name matches the closed-app-push-delivery design spec.
3. Skips a second append if that `date` is already present in the file (idempotent re-run).

This workflow keeps human operators away from direct SQL against the relay database while preserving an append-only audit trail suitable for selective publication.
