# Design

## Context

This is the first change in an empty repository. See `proposal.md` for motivation. The bench is a static, reproducible topology: five containers and their init scripts, plus the documentation that fixes the measurement methodology. There is no application code, no data generator, and no benchmark runner yet — this change only delivers the bench and the methodology.

The benchmark plan (`benchmark/plan.md`) fixes the logical event model, the mandatory access pattern (chronology of one user's events over a time range), and the phase-1 fairness rule (native types, reasonable defaults, no remapping tricks). The five approved image tags are fixed by the requirements.

## Goals / Non-Goals

**Goals:**

- A single `docker-compose.yml` that deterministically reproduces the five-engine bench on a clean host.
- Identical logical schema across engines, expressed in each engine's native types.
- One mandatory composite `(userId, timestamp)` index in every server-indexed engine; MinIO uses day-prefixed objects + client-side scan.
- A written, exact, per-engine settle procedure and a primary `du -sb` measurement with engine-internal cross-checks.
- A headline metric that is unambiguous and reproducible.

**Non-Goals:**

- Data generation, loading, or measurement automation (later changes).
- Phase-2 optimizations (json/jsonb, remapped keys, Avro, custom codecs).
- Container CPU/RAM limits.
- Replication, sharding, or clustering.
- Digest-pinning of images (noted as future hardening, not required now).

## Decisions

### D1 — One Compose file, five services, fixed service names

`benchmark/docker-compose.yml` defines exactly five services: `postgres`, `timescaledb`, `mongodb`, `clickhouse`, `minio`. Each is one container. A single file keeps the bench inspectable and satisfies the "exactly five services" acceptance criterion (no helper/init services inside Compose).

- Alternative considered: an extra `minio-init` (mc) service to create the bucket. Rejected — it would make six services and violate "exactly five". Bucket creation is a documented host command instead (D9).

### D2 — Pinned images

| Service | Image |
|---------|-------|
| postgres | `postgres:16.6` |
| timescaledb | `timescale/timescaledb:2.17.2-pg16` |
| mongodb | `mongo:7.0.14` |
| clickhouse | `clickhouse/clickhouse-server:24.8` |
| minio | `pgsty/silo:RELEASE.2026-10-26T00-00-00Z` |

These are the approved tags. Note: `clickhouse/clickhouse-server:24.8` is branch-level (resolves to the latest 24.8.x); the requirements approve this exact tag, so it is used as-is. For extra reproducibility, the methodology instructs recording the resolved image digest at run time (without changing the tag).

MinIO Community Edition was discontinued and its Docker Hub / anonymous Quay images were removed (2026). The bench uses **Silo** (`pgsty/silo`), a maintained AGPL-3.0 drop-in fork of MinIO with the same S3 API, `server /data` command, `MINIO_ROOT_*` credentials, ports, and on-disk format.

- Alternative considered: pinning ClickHouse to a full patch tag. Rejected because the approved requirement lists `24.8`; changing it would silently alter an approved requirement.

### D3 — Host port mapping

| Service | Host → container | Purpose |
|---------|------------------|---------|
| postgres | 5432 → 5432 | SQL |
| timescaledb | 5433 → 5432 | SQL (avoids clash with postgres) |
| mongodb | 27017 → 27017 | MongoDB wire protocol |
| clickhouse | 8123 → 8123, 9000 → 9000 | HTTP, native TCP |
| minio | 9002 → 9000, 9001 → 9001 | S3 API, web console |

ClickHouse keeps its conventional 9000/8123; MinIO's S3 API is remapped to host 9002 to avoid clashing with ClickHouse's 9000.

### D4 — Credentials and database names

One shared credential pair keeps every connection string deterministic: user `bench`, password `benchpass` (≥8 chars, required by MinIO). Database name is `benchmark` everywhere a database is named.

- postgres/timescaledb: `POSTGRES_USER=bench`, `POSTGRES_PASSWORD=benchpass`, `POSTGRES_DB=benchmark`.
- mongodb: `MONGO_INITDB_ROOT_USERNAME=bench`, `MONGO_INITDB_ROOT_PASSWORD=benchpass`, `MONGO_INITDB_DATABASE=benchmark`; URI `mongodb://bench:benchpass@localhost:27017/benchmark?authSource=admin`.
- minio: `MINIO_ROOT_USER=bench`, `MINIO_ROOT_PASSWORD=benchpass`.
- clickhouse: no auth (default local benchmark); accessed over HTTP/native without credentials.

- Alternative considered: no authentication at all. Rejected — the approved requirements are silent on auth, and fixed credentials keep the "realistic standalone engine" context reproducible without affecting disk-size measurements.

### D5 — Named volumes

One named volume per engine, all declared in the top-level `volumes:` section: `pg_data`, `ts_data`, `mongo_data`, `ch_data`, `minio_data`. No bind mounts, no anonymous volumes. Mountpoints are the data dirs required by each image (e.g. `/var/lib/postgresql/data`, `/data/db`, `/var/lib/clickhouse`, `/data`).

- Rationale: named volumes are the object `du -sb` measures (D14); they also satisfy the acceptance criterion "own named volume, no bind mounts/anonymous volumes".

### D6 — Standalone single-node

No replication or sharding is configured anywhere:

- MongoDB runs without `--replSet` (default standalone `mongod`).
- ClickHouse uses a single replica with the default `MergeTree` (no `ReplicatedMergeTree`, no Distributed tables).
- PostgreSQL/TimescaleDB run as single instances (no streaming replication, no logical replication).
- MinIO runs in single-node single-drive mode (no erasure parity for a single drive).

### D7 — Native audit-event schema per engine

Logical model: `id` UUID, `timestamp` datetime-with-tz ms precision, `userId` int64, `eventType` enum `TYPE_1`..`TYPE_50`, `metadata` JSON object.

| Engine | `id` | `timestamp` | `userId` | `eventType` | `metadata` |
|--------|------|-------------|----------|-------------|------------|
| PostgreSQL | `UUID` | `TIMESTAMPTZ` | `BIGINT` | native `ENUM` type | `JSONB` |
| TimescaleDB | `UUID` | `TIMESTAMPTZ` | `BIGINT` | native `ENUM` type | `JSONB` |
| MongoDB | `_id: UUID` (binary subtype 4) | `Date` (ms) | `Long` | `String` (no native enum) | `Object` |
| ClickHouse | `UUID` | `DateTime64(3, 'UTC')` | `Int64` | `Enum8` | `String` (JSON text) |
| MinIO | JSON field | ISO-8601 string, ms + tz | JSON number | JSON string | JSON object |

- PostgreSQL/TimescaleDB: `id` is a plain `UUID` column, **not** a primary key, so the only index is the mandatory composite index (D8). Uniqueness is guaranteed by the data generator, not enforced by an extra index. This keeps the headline metric (data + the one mandatory index) clean.
- MongoDB: `id` maps to `_id` as a binary UUID. MongoDB always maintains an unavoidable `_id` index; this is documented and reported in the data-vs-index row, not the headline (see D14/D15 and Risks).
- ClickHouse: `eventType` uses native `Enum8` (50 values fit 8 bits); `metadata` is stored as `String` holding JSON text because the `JSON`/`Object` type is experimental in 24.8 and would be a phase-2 trick. Phase 1 keeps stable types and default LZ4 codec.
- MinIO: no schema; each JSON Lines record carries the same five logical fields.

### D8 — Mandatory composite index

- PostgreSQL / TimescaleDB: `CREATE INDEX idx_audit_user_ts ON audit_events (user_id, timestamp);`
- MongoDB: `db.audit_events.createIndex({ userId: 1, timestamp: 1 });`
- ClickHouse: `ORDER BY (user_id, timestamp)` and `PRIMARY KEY (user_id, timestamp)` — ClickHouse's sparse primary index is the `(userId, timestamp)` index.
- MinIO: index N/A; access is via day-prefixed object names plus a client-side scan. This is stated in the MinIO docs.

### D9 — MinIO JSON Lines layout and bucket creation

Bucket `audit-events`. Object key pattern: `audit-events/YYYY/MM/DD/<batch>.jsonl` (day partition), each object immutable and containing one JSON object per line. Bucket creation is a documented host command, not a Compose service:

```bash
docker compose -f benchmark/docker-compose.yml exec -T minio \
  sh -c 'mc alias set local http://localhost:9000 bench benchpass && mc mb local/audit-events'
```

(run against the Compose network; exact network name documented in README). Alternatively `mc` can be installed on the host.

### D10 — Compression settings

| Engine | Compression | How it is enabled |
|--------|-------------|-------------------|
| PostgreSQL | TOAST (default) | default `pglz`/TOAST for out-of-line values; nothing extra to enable |
| TimescaleDB | native columnar compression | `ALTER TABLE audit_events SET (timescaledb.compress, timescaledb.compress_segmentby = 'user_id', timescaledb.compress_orderby = 'timestamp DESC');` |
| MongoDB | WiredTiger `snappy` (default) | default storage engine block compression |
| ClickHouse | LZ4 (default) | default MergeTree column codec (no explicit codec set) |
| MinIO | none | no server-side compression; raw object bytes |

These are the engines' supported defaults, matching "reasonable default compression" without phase-2 tricks.

### D11 — Init mechanism

Init scripts are checked into `benchmark/init/<engine>/` and mounted read-only into each image's init directory, so they run automatically on first `docker compose up -d` on a clean volume:

- postgres, timescaledb: `./init/<engine>/:/docker-entrypoint-initdb.d/:ro` (`.sql`).
- mongodb: `./init/mongodb/:/docker-entrypoint-initdb.d/:ro` (`.js`).
- clickhouse: `./init/clickhouse/:/docker-entrypoint-initdb.d/:ro` (`.sql`).
- minio: no schema; bucket creation is the documented command in D9.

TimescaleDB's script additionally runs `SELECT create_hypertable('audit_events', 'timestamp');` then creates the index and enables compression (D10).

### D12 — Health checks

Each service declares a `healthcheck` so readiness is programmatically verifiable:

- postgres / timescaledb: `pg_isready -U bench -d benchmark`
- mongodb: `mongosh --quiet -u bench -p benchpass --authenticationDatabase admin --eval 'db.adminCommand("ping").ok'`
- clickhouse: `clickhouse-client --query 'SELECT 1'`
- minio: `curl -sf http://localhost:9000/minio/health/live`

Risk note: exact binary availability differs slightly across images; the implementer verifies each healthcheck returns healthy and may adjust only the command path (not the five-service topology).

### D13 — Per-engine settle procedure

Run after load, before measurement, to reach a stable settled state:

- **PostgreSQL**
  ```bash
  psql -c 'CHECKPOINT;'
  psql -c 'VACUUM (FULL, ANALYZE) audit_events;'
  psql -c 'CHECKPOINT;'
  ```
- **TimescaleDB**
  ```bash
  psql -c 'CHECKPOINT;'
  psql -c "SELECT compress_chunk(c) FROM show_chunks('audit_events') c;"
  psql -c 'VACUUM (ANALYZE) audit_events;'
  psql -c 'CHECKPOINT;'
  ```
- **MongoDB**
  ```js
  db.runCommand({ compact: 'audit_events' });
  db.adminCommand({ fsync: 1 });
  ```
- **ClickHouse**
  ```sql
  OPTIMIZE TABLE benchmark.audit_events FINAL;
  SYSTEM FLUSH LOGS;
  ```
- **MinIO** — no server-side settle; verify all uploads completed and no multipart parts remain, then measure.

### D14 — Primary measurement (`du -sb`) and headline metric

Primary measurement for every engine is `du -sb` over the named volume's host mountpoint after settle:

```bash
docker volume inspect bench_<engine>_data --format '{{.Mountpoint}}'
sudo du -sb "$(docker volume inspect bench_<engine>_data --format '{{.Mountpoint}}')"
```

Headline metric = settled on-disk bytes of **data + `(userId, timestamp)` index**, excluding WAL/journals and excluding container images (images are never measured — only the named volume is). Concretely:

- PostgreSQL / TimescaleDB: `du -sb(volume) − du -sb(pg_wal)`. There is no other index, so this equals heap + TOAST + the composite index.
- MongoDB: `du -sb(volume) − du -sb(journal)`. This includes WiredTiger data plus both indexes (`_id` is unavoidable; see D15 and Risks).
- ClickHouse: `du -sb(volume)`. MergeTree has no separate redo log; `OPTIMIZE ... FINAL` collapses parts first.
- MinIO: headline = object bytes (data) with index 0. Object bytes come from `mc du`; `du -sb(volume)` also includes `.minio.sys` metadata, recorded as an extra row.

WAL/journal and data-vs-index are always recorded as separate rows (D15).

### D15 — Engine-internal cross-checks (data vs index and WAL rows)

| Engine | Data vs index | WAL/journal row |
|--------|---------------|-----------------|
| PostgreSQL | `pg_total_relation_size('audit_events')` (heap + TOAST + index) and `pg_relation_size('idx_audit_user_ts')` (index alone) | `du -sb pg_wal` |
| TimescaleDB | `hypertable_detailed_size('audit_events')` (table/index/toast) | `du -sb pg_wal` |
| MongoDB | `db.audit_events.stats({scale:1})` → `storageSize`, `totalIndexSize`, `indexSizes` | `du -sb journal` |
| ClickHouse | `system.parts` → `data_compressed_bytes`, `primary_key_bytes_in_memory`, `marks_bytes` | N/A (no journal) |
| MinIO | `mc du` object bytes vs `du -sb` volume (`.minio.sys` overhead) | N/A |

MongoDB note: WiredTiger stores data and both indexes inside the same collection files, and the `_id` index is mandatory. Its size is reported in `indexSizes` (data-vs-index row); the headline still follows D14 and is therefore inclusive of `_id` for MongoDB. This is called out explicitly in Risks for transparency.

### D16 — Repository file layout

```
benchmark/
  docker-compose.yml
  README.md
  docs/
    methodology.md
    report-template.md
  init/
    postgres/001-schema.sql
    timescaledb/001-schema.sql
    mongodb/001-schema.js
    clickhouse/001-schema.sql
```

All public text and comments are English.

### D17 — Capacity for 100M records

No volume size quotas or engine storage caps are set; Docker named volumes default to unlimited. Documentation states readiness for 100,000,000 records and gives a rough raw-size estimate (~tens of GB depending on `metadata` variability) so operators can size the host disk. No hard limit below 100M exists.

## Architecture overview

```mermaid
graph LR
    subgraph Host
        M["measure: sudo du -sb &lt;volume mountpoint&gt;"]
    end
    subgraph "docker-compose.yml (benchmark/)"
        PG[("postgres:16.6")] --- VPG[("pg_data")]
        TS[("timescaledb:2.17.2-pg16")] --- VTS[("ts_data")]
        MG[("mongo:7.0.14")] --- VMG[("mongo_data")]
        CH[("clickhouse:24.8")] --- VCH[("ch_data")]
        MN[("silo RELEASE.2026-10-26")] --- VMN[("minio_data")]
    end
    M --- VPG
    M --- VTS
    M --- VMG
    M --- VCH
    M --- VMN
```

## Risks / Trade-offs

- **MongoDB `_id` index is unavoidable** → the headline for MongoDB includes the `_id` index, unlike PostgreSQL/ClickHouse which have no such extra index. Mitigation: document it and always report `indexSizes` in the data-vs-index row so the comparison stays transparent; the user accepts or adjusts this framing at G4.
- **ClickHouse `24.8` is a branch tag** → minor patch drift between runs. Mitigation: record the resolved image digest in the methodology; do not change the approved tag.
- **Health-check binaries vary by image** → an image may lack `curl`/`clickhouse-client` in exactly the assumed form. Mitigation: implementer verifies each healthcheck turns healthy and adjusts only the command path.
- **`VACUUM FULL` / `compact` rewrite data and need free space** → transient double-disk during settle. Mitigation: methodology notes the space requirement; measurement happens after settle completes.
- **`du -sb` needs host access to `/var/lib/docker/volumes`** → Mitigation: methodology documents `sudo` and the exact `docker volume inspect` mountpoint.

## Migration Plan

Not applicable — greenfield bench with no prior configuration. Rollback is `docker compose down -v` (destroys the named volumes) after discarding the change.

## Open Questions

None that would change the specs or task breakdown. The only deferrable note is optional image-digest pinning, which can be added later without changing behavior.
