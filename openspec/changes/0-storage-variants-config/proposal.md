# Proposal

## Why

The project needs a reproducible benchmark to find the cheapest on-disk storage for audit logs. No measurement can be trusted without a fair, deterministic test bench first: the five candidate engines running as pinned, single-node Docker containers with the same logical schema, the mandatory access-pattern index, documented compression, and a documented disk-measurement methodology.

## What Changes

- Add a single Docker Compose file defining exactly five engine services: PostgreSQL, TimescaleDB, MongoDB, ClickHouse, and MinIO, one container per engine.
- Pin every image to a fixed tag (no `latest`), per the approved list.
- Give each engine its own named Docker volume; no bind mounts or anonymous volumes for data.
- Configure every engine as standalone single-node, without replication or sharding.
- Add per-engine initialization that creates the audit-event schema in native types (`id`, `timestamp`, `userId`, `eventType`, `metadata`) and, for server-indexed engines, the composite `(userId, timestamp)` index.
- Define MinIO storage as immutable JSON Lines objects partitioned by day.
- Enable and document reasonable default compression per engine.
- Add an English-language bench README, a disk-measurement methodology (primary `du -sb` method, per-engine settle procedure, engine-internal cross-checks, headline metric), and a measurement report template.

## Capabilities

### New Capabilities

- `storage-variants`: the reproducible five-engine bench — topology, pinned images, named volumes, standalone mode, native audit-event schema, composite index, MinIO JSON Lines layout, compression settings, phase-1 constraints, capacity, and health/readiness.
- `measurement-methodology`: how on-disk footprint is measured — primary `du -sb` method, per-engine settle procedure, engine-internal cross-checks, headline metric, and separate WAL/journal and data-vs-index rows.

### Modified Capabilities

None — this is the first proposal in an empty project.

## Impact

- New files under `benchmark/`: `docker-compose.yml`, per-engine init scripts under `benchmark/init/`, a `README.md`, a measurement methodology document, and a measurement report template.
- Five new Docker named volumes are created at first `docker compose up -d`.
- No existing application code is affected (none exists yet). No data generator, loader, or benchmark runner is built in this change.

## Non-Goals

- No dataset generator, loader, or benchmark runner — those are later changes.
- No phase-2 optimizations (json vs jsonb, field remapping/shortening, Avro, custom codecs).
- No CPU/RAM limits for containers; all engines share one host.
- No replication, sharding, or clustering.
- No application code and no REST APIs.

## Success Criteria

- `docker compose config` validates and shows exactly five services, five pinned images, and five named volumes with no bind mounts or anonymous data volumes.
- The audit-event schema and `(userId, timestamp)` index initialize for PostgreSQL, TimescaleDB, MongoDB, and ClickHouse; MinIO documents index N/A with prefix + client-side scan.
- Compression settings are enabled and documented per engine.
- The methodology documents `du -sb` as primary, per-engine settle, engine-internal cross-checks, and a headline metric ("data + (userId, timestamp) index", excluding WAL/journals and container images) with separate WAL/journal and data-vs-index rows.
- Bench documentation is in English and confirms readiness for 100,000,000 records.
- After `docker compose up -d`, all five containers are healthy and each engine responds programmatically.
