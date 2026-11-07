# Disk Measurement Methodology

This document fixes how on-disk footprint is measured for the five-engine
bench. All commands are exact and reproducible from the repository root.

## 1. Scope

- Primary measurement: `du -sb` over the engine's named-volume mountpoint,
  after the per-engine settle procedure.
- Cross-check: each engine's native size report, recorded next to `du -sb`.
- Headline metric: settled on-disk bytes of **data + the `(userId, timestamp)`
  index**, excluding WAL/journals and excluding container images (images are
  never measured; only the named volume is measured).
- WAL/journal bytes and data-vs-index bytes are recorded as separate rows.

The named volumes are: `benchmark_pg_data`, `benchmark_ts_data`,
`benchmark_mongo_data`, `benchmark_ch_data`, `benchmark_minio_data`.

## 2. Primary method (`du -sb`)

For each engine, resolve the volume mountpoint and measure its settled bytes:

```bash
docker volume inspect benchmark_pg_data --format '{{.Mountpoint}}'
sudo du -sb "$(docker volume inspect benchmark_pg_data --format '{{.Mountpoint}}')"
```

Repeat with `benchmark_ts_data`, `benchmark_mongo_data`, `benchmark_ch_data`,
and `benchmark_minio_data`. `du -sb` reports a single byte count including all
files and subdirectories (apparent size summed, not disk blocks).

`du -sb` measures **apparent size** (logical file size), not allocated disk
blocks. Engines that preallocate or use sparse files — notably MongoDB
WiredTiger (`*.wt`) — can show a meaningful gap between apparent size and
actually allocated blocks. Record the block-level value as an additional
cross-check where this matters (MongoDB, ClickHouse):

```bash
sudo du -sB1 "$(docker volume inspect benchmark_mongo_data --format '{{.Mountpoint}}')"
```

`du -sB1` reports allocated blocks in 1-byte units (real disk usage), unlike
`du -sb` (apparent size). Record it next to `du -sb` in the report.

## 3. Per-engine settle procedure

Run the settle steps for the engine under test **before** recording `du -sb`.
The settle procedure brings the engine to a stable, fully-written state.

### PostgreSQL

```bash
docker compose -f benchmark/docker-compose.yml exec -T postgres psql -U bench -d benchmark -c 'CHECKPOINT;'
docker compose -f benchmark/docker-compose.yml exec -T postgres psql -U bench -d benchmark -c 'VACUUM (FULL, ANALYZE) audit_events;'
docker compose -f benchmark/docker-compose.yml exec -T postgres psql -U bench -d benchmark -c 'CHECKPOINT;'
```

### TimescaleDB

```bash
docker compose -f benchmark/docker-compose.yml exec -T timescaledb psql -U bench -d benchmark -c 'CHECKPOINT;'
docker compose -f benchmark/docker-compose.yml exec -T timescaledb psql -U bench -d benchmark -c "SELECT compress_chunk(c) FROM show_chunks('audit_events') c;"
docker compose -f benchmark/docker-compose.yml exec -T timescaledb psql -U bench -d benchmark -c 'VACUUM (ANALYZE) audit_events;'
docker compose -f benchmark/docker-compose.yml exec -T timescaledb psql -U bench -d benchmark -c 'CHECKPOINT;'
```

### MongoDB

```bash
docker compose -f benchmark/docker-compose.yml exec -T mongodb mongosh --quiet -u bench -p benchpass --authenticationDatabase admin benchmark --eval 'db.runCommand({ compact: "audit_events" });'
docker compose -f benchmark/docker-compose.yml exec -T mongodb mongosh --quiet -u bench -p benchpass --authenticationDatabase admin admin --eval 'db.adminCommand({ fsync: 1 });'
```

### ClickHouse

```bash
docker compose -f benchmark/docker-compose.yml exec -T clickhouse clickhouse-client --query 'OPTIMIZE TABLE benchmark.audit_events FINAL;'
docker compose -f benchmark/docker-compose.yml exec -T clickhouse clickhouse-client --query 'SYSTEM FLUSH LOGS;'
```

### MinIO

MinIO has no server-side settle. Before measuring, verify all uploads completed
and no multipart parts remain (for example, list `audit-events` and confirm
there are no `.part` uploads), then run `du -sb` on `benchmark_minio_data`.

## 4. Engine-internal cross-checks

Record the native size report next to the `du -sb` value.

### PostgreSQL

```bash
# Data + index + toast, and the (userId, timestamp) index alone.
docker compose -f benchmark/docker-compose.yml exec -T postgres psql -U bench -d benchmark -c "SELECT pg_total_relation_size('audit_events'), pg_relation_size('idx_audit_user_ts');"

# WAL directory
sudo du -sb "$(docker volume inspect benchmark_pg_data --format '{{.Mountpoint}}')/pg_wal"
```

### TimescaleDB

```bash
docker compose -f benchmark/docker-compose.yml exec -T timescaledb psql -U bench -d benchmark -c "SELECT * FROM hypertable_detailed_size('audit_events');"

# WAL directory
sudo du -sb "$(docker volume inspect benchmark_ts_data --format '{{.Mountpoint}}')/pg_wal"
```

### MongoDB

```bash
docker compose -f benchmark/docker-compose.yml exec -T mongodb mongosh --quiet -u bench -p benchpass --authenticationDatabase admin benchmark --eval 'db.audit_events.stats({ scale: 1 })'

# Journal directory
sudo du -sb "$(docker volume inspect benchmark_mongo_data --format '{{.Mountpoint}}')/journal"
```

### ClickHouse

```bash
docker compose -f benchmark/docker-compose.yml exec -T clickhouse clickhouse-client --query "SELECT sum(data_compressed_bytes), sum(bytes_on_disk), sum(marks_bytes) FROM system.parts WHERE database = 'benchmark' AND table = 'audit_events' AND active;"
```

`data_compressed_bytes` is the compressed on-disk column data; `bytes_on_disk`
is the total on-disk size of the active parts (including the sparse primary
index and marks). `primary_key_bytes_in_memory` is a RAM metric and is
intentionally not used for the on-disk cross-check.

### MinIO

```bash
# Object bytes (data) via mc
docker compose -f benchmark/docker-compose.yml exec -T minio \
  sh -c 'mc alias set local http://localhost:9000 bench benchpass >/dev/null && mc du local/audit-events'

# Volume bytes including .minio.sys metadata
sudo du -sb "$(docker volume inspect benchmark_minio_data --format '{{.Mountpoint}}')"
```

## 5. Headline metric

The headline metric is settled on-disk bytes of **data + the `(userId,
timestamp)` index**, excluding WAL/journals and excluding container images.

| Engine       | Headline computation from `du -sb`                                        |
|--------------|---------------------------------------------------------------------------|
| PostgreSQL   | `du -sb(volume) - du -sb(pg_wal)`                                         |
| TimescaleDB  | `du -sb(volume) - du -sb(pg_wal)`                                         |
| MongoDB      | `du -sb(volume) - du -sb(journal)` (still includes the unavoidable `_id` index; see note) |
| ClickHouse   | `du -sb(volume)` (MergeTree has no separate redo log)                     |
| MinIO        | object bytes from `mc du` (index = 0); `du -sb(volume)` also includes `.minio.sys`, recorded separately |

Notes:

- PostgreSQL/TimescaleDB have exactly one index, so `du -sb(volume) -
  du -sb(pg_wal)` equals heap + TOAST + the composite index.
- MongoDB stores data and both indexes (`_id` is mandatory and unavoidable)
  inside the same WiredTiger files. The headline is therefore inclusive of
  `_id`; the data-vs-index row reports `indexSizes` so the comparison stays
  transparent.
- ClickHouse's `OPTIMIZE ... FINAL` collapses parts first; MergeTree has no
  separate WAL/journal directory to subtract.

WAL/journal bytes and data-vs-index bytes are always recorded as separate rows
in the report.

## 6. Space requirement

`VACUUM FULL` (PostgreSQL/TimescaleDB) and MongoDB `compact` rewrite the data
and temporarily need free space (transient double-disk). Measurement happens
after settle completes, so the temporary space is released before `du -sb`.

## 7. Reproducibility

- Record the resolved image digests before a run, especially for ClickHouse
  (`24.8` is a branch tag that may advance within the 24.8 series):

  ```bash
  docker compose -f benchmark/docker-compose.yml images
  docker compose -f benchmark/docker-compose.yml config --images
  ```

- Use the same Compose file, image tags, init scripts, and settle commands on
  every host. A clean run is `docker compose ... down -v` followed by
  `docker compose ... up -d`.
