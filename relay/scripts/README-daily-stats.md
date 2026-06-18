# Daily relay statistics file

The relay exposes `GET http://127.0.0.1:9091/internal/stats/daily?date=YYYY-MM-DD` (bind address overridden by `STATS_LISTEN_ADDR` inside the container, or disabled with `STATS_LISTEN_ADDR=-`). Only **loopback callers as seen by the relay process** receive data; any other remote address gets HTTP 404.

## Containerized deployment (VPS production)

When the relay runs inside Docker (see `relay/compose.yml` or
`deploy/compose.production-stack.yml`), port 9091 is **not** published
to the host. Cron on the VPS must use:

**`scripts/daily-stats-append-via-docker.sh`**

This wrapper runs `curl` in the relay container's network namespace
(`docker run --network container:compartarenta-relay`). Do **not** cron
`daily-stats-append.sh` from the host — it will log
`curl: (7) Failed to connect to 127.0.0.1 port 9091`.

Example crontab (00:07 UTC):

```cron
CRON_TZ=UTC
7 0 * * * /srv/compartarenta-relay/source/relay/scripts/daily-stats-append-via-docker.sh >> /srv/compartarenta-stats/cron.log 2>&1
```

Environment:

- `COMPARTARENTA_RELAY_CONTAINER` — default `compartarenta-relay`
- `STATS_FILE_PATH` — default `/srv/compartarenta-stats/daily.jsonl`

See also `docs/relay-deployment.md` and `docs/stack-deployment.md`.

## Bare-metal / host loopback (uncommon)

If the relay binary runs directly on the host (not in Docker), cron
`scripts/daily-stats-append.sh` under the relay UNIX user.

The script:

1. Calls the stats endpoint for **yesterday** in UTC.
2. Appends one JSON object as a single line to `STATS_FILE_PATH` (default `/srv/compartarenta-stats/daily.jsonl`). The variable name matches the closed-app-push-delivery design spec.
3. Skips a second append if that `date` is already present in the file (idempotent re-run).

Environment for the bare-metal script:

- `RELAY_STATS_URL` — default `http://127.0.0.1:9091/internal/stats/daily`
- `STATS_FILE_PATH` — default `/srv/compartarenta-stats/daily.jsonl`

Each appended line is terminated by a single newline: the relay's JSON encoder already ends the body with `\LF`; the scripts do not add a second newline (avoiding a spurious empty line in `wc -l` / JSONL consumers).

This workflow keeps human operators away from direct SQL against the relay database while preserving an append-only audit trail suitable for selective publication.
