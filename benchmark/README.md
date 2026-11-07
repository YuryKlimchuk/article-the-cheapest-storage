# Storage Variants Benchmark

A reproducible five-engine bench for measuring the on-disk footprint of the
same audit-event dataset. This change delivers the static topology (Compose
file + init scripts) and the measurement methodology. It does **not** include a
data generator, loader, or benchmark runner.

## Engines

| Service       | Image                                      | Host ports              | Notes                          |
|---------------|--------------------------------------------|-------------------------|--------------------------------|
| `postgres`    | `postgres:16.6`                            | `5432 -> 5432`          | Heap + TOAST, default compression |
| `timescaledb` | `timescale/timescaledb:2.17.2-pg16`        | `5433 -> 5432`          | Hypertable + native columnar compression |
| `mongodb`     | `mongo:7.0.14`                             | `27017 -> 27017`        | WiredTiger snappy (default) |
| `clickhouse`  | `clickhouse/clickhouse-server:24.8`        | `8123 -> 8123`, `9000 -> 9000` | MergeTree LZ4 (default) |
| `minio`       | `pgsty/silo:RELEASE.2026-10-26T00-00-00Z`  | `9002 -> 9000`, `9001 -> 9001` | S3 API, web console (Silo fork) |

All engines run as standalone single-node instances. There is no replication
and no sharding.

> **Note on MinIO.** MinIO Community Edition was discontinued (2025) and its
> images were removed from public registries. This bench therefore uses **Silo**
> (`pgsty/silo`), a maintained AGPL-3.0 drop-in fork of MinIO with the same
> S3 API, `server /data` command, `MINIO_ROOT_*` credentials, ports, and
> on-disk format.

## Credentials and databases

| Service                | User / access key | Password / secret key | Database     |
|------------------------|-------------------|------------------------|--------------|
| `postgres`             | `bench`           | `benchpass`            | `benchmark`  |
| `timescaledb`          | `bench`           | `benchpass`            | `benchmark`  |
| `mongodb`              | `bench`           | `benchpass`            | `benchmark`  |
| `clickhouse`           | none (local)      | none                   | `benchmark`  |
| `minio`                | `bench`           | `benchpass`            | bucket `audit-events` |

## Prerequisites

- Docker Engine (verified with `29.3.0`) and Docker Compose plugin
  (verified with `5.1.1`).
- Read access to Docker named volumes for measurement
  (`sudo` is required to run `du` over `/var/lib/docker/volumes`).

## Start and stop

Start the full bench:

```bash
docker compose -f benchmark/docker-compose.yml up -d
```

Stop it (keeps the named volumes and their data):

```bash
docker compose -f benchmark/docker-compose.yml down
```

Stop it and destroy all measured data:

```bash
docker compose -f benchmark/docker-compose.yml down -v
```

The first `up -d` creates five named volumes. The Compose file declares them as
`pg_data`, `ts_data`, `mongo_data`, `ch_data`, `minio_data`; on disk Docker
prefixes them with the project name, so they appear as `benchmark_pg_data`,
`benchmark_ts_data`, `benchmark_mongo_data`, `benchmark_ch_data`,
`benchmark_minio_data`. The init scripts run on this first start.
The init scripts only run when a volume is empty; re-running `up -d` on a
populated volume does not recreate the schema.

## Host access strings

```bash
# PostgreSQL
psql "postgresql://bench:benchpass@localhost:5432/benchmark"

# TimescaleDB
psql "postgresql://bench:benchpass@localhost:5433/benchmark"

# MongoDB
mongosh "mongodb://bench:benchpass@localhost:27017/benchmark?authSource=admin"

# ClickHouse (HTTP and native)
curl "http://localhost:8123/?query=SELECT%201"
clickhouse-client --host 127.0.0.1 --port 9000 --query 'SELECT 1'

# MinIO (S3 API and web console)
# S3 API:      http://localhost:9002
# Web console: http://localhost:9001
```

## Healthcheck verification

Every service declares a `healthcheck`. Verify all five are healthy:

```bash
docker compose -f benchmark/docker-compose.yml ps
```

Programmatic per-engine checks:

```bash
docker compose -f benchmark/docker-compose.yml exec -T postgres pg_isready -U bench -d benchmark
docker compose -f benchmark/docker-compose.yml exec -T timescaledb pg_isready -U bench -d benchmark
docker compose -f benchmark/docker-compose.yml exec -T mongodb mongosh --quiet -u bench -p benchpass --authenticationDatabase admin --eval 'db.adminCommand("ping").ok'
docker compose -f benchmark/docker-compose.yml exec -T clickhouse clickhouse-client --query 'SELECT 1'
curl -sf http://localhost:9002/minio/health/live
```

## Schema and index

The logical audit event has five fields: `id` (UUID), `timestamp` (datetime
with timezone, millisecond precision), `userId` (int64), `eventType`
(`TYPE_1`..`TYPE_50`), and `metadata` (JSON object).

- **PostgreSQL / TimescaleDB**: table `audit_events` with native
  `UUID` / `TIMESTAMPTZ` / `BIGINT` / enum / `JSONB` types and the composite
  `(user_id, timestamp)` index. SQL engines use snake_case column names
  (`user_id`, `event_type`); the logical names are unchanged.
- **MongoDB**: collection `audit_events` with `_id` as a binary UUID,
  `Date` / `Long` / `String` / `Object` fields and the composite
  `{ userId: 1, timestamp: 1 }` index.
- **ClickHouse**: table `benchmark.audit_events` on `MergeTree` with
  `UUID` / `DateTime64(3, 'UTC')` / `Int64` / `Enum8` / `String` columns and
  `ORDER BY (user_id, timestamp)` / `PRIMARY KEY (user_id, timestamp)`.
- **MinIO**: no server index (index = N/A). Access is via day-prefixed object
  names plus a client-side scan.

## MinIO bucket and JSON Lines layout

Events are stored as immutable JSON Lines (`.jsonl`) objects under a day
prefix:

```text
audit-events/YYYY/MM/DD/<batch>.jsonl
```

Each object contains one JSON record per line and is never modified after
upload.

Create the `audit-events` bucket using the `mc` client bundled in the Silo
container:

```bash
docker compose -f benchmark/docker-compose.yml exec -T minio \
  sh -c 'mc alias set local http://localhost:9000 bench benchpass && mc mb local/audit-events'
```

Alternatively, install `mc` on the host and run the same `alias set` + `mb`
commands against `http://localhost:9002`.

## Measuring disk usage

Measurement is documented in [`docs/methodology.md`](docs/methodology.md) and
recorded using [`docs/report-template.md`](docs/report-template.md). In short:
settle each engine, then run `du -sb` over its named-volume mountpoint, and
record the engine-internal size report as a cross-check.

## Capacity for 100,000,000 records

The bench is ready to accept up to 100,000,000 records. No volume size quota or
engine storage cap is set; Docker named volumes default to unlimited, so there
is no configured limit below 100M. Operators should size the host disk for the
expected raw size (roughly tens of GB depending on `metadata` variability) plus
transient double-disk during the settle procedures that rewrite data
(`VACUUM FULL`, MongoDB `compact`).
