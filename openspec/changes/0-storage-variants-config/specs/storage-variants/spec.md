# Spec Delta

## Purpose

Defines the reproducible five-engine storage bench: the candidate engines, their pinned images, volumes, standalone mode, native audit-event schema, mandatory index, MinIO layout, compression, phase-1 constraints, capacity, and readiness.

## ADDED Requirements

### Requirement: Five engines in a single Compose file
The bench SHALL consist of exactly five storage engines — PostgreSQL, TimescaleDB, MongoDB, ClickHouse, and MinIO — each in its own container, defined by one Docker Compose file.

#### Scenario: Compose file describes exactly five services
- **WHEN** `docker compose config` is run against the bench Compose file
- **THEN** the command validates and reports exactly five services named `postgres`, `timescaledb`, `mongodb`, `clickhouse`, and `minio`

### Requirement: Pinned image tags
Each engine SHALL use a fully pinned image tag, never `latest`, with the exact tags: `postgres:16.6`, `timescale/timescaledb:2.17.2-pg16`, `mongo:7.0.14`, `clickhouse/clickhouse-server:24.8`, and `pgsty/silo:RELEASE.2026-10-26T00-00-00Z`.

#### Scenario: No unpinned images
- **WHEN** the `image:` value of every service is inspected
- **THEN** each equals its approved pinned tag and no service uses `latest` or a floating tag

### Requirement: Dedicated named volumes
Each engine SHALL persist its data on its own named Docker volume, with no bind mounts and no anonymous volumes for data.

#### Scenario: One named volume per engine
- **WHEN** `docker compose config` is run
- **THEN** each of the five services mounts one named volume and the top-level `volumes:` section declares five named volumes, with no data bind mounts

### Requirement: Standalone single-node mode
Each engine SHALL run as a standalone single node, without replication and without sharding.

#### Scenario: No replication or sharding configuration
- **WHEN** the Compose file and per-engine configuration are inspected
- **THEN** no replica set, replication, or sharding configuration is present for any engine

### Requirement: Native audit-event schema
For PostgreSQL, TimescaleDB, MongoDB, and ClickHouse, the initialization SHALL define the audit-event schema with fields `id` (UUID), `timestamp` (datetime with timezone, millisecond precision), `userId` (int64), `eventType` (enum of `TYPE_1`..`TYPE_50`), and `metadata` (JSON object), using each engine's native types.

#### Scenario: Schema fields present after initialization
- **WHEN** each engine is queried after its init scripts run
- **THEN** the audit-event container holds the five fields with the correct logical types (`id`, `timestamp`, `userId`, `eventType`, `metadata`)

### Requirement: Composite index and MinIO access path
PostgreSQL, TimescaleDB, MongoDB, and ClickHouse SHALL create a composite `(userId, timestamp)` index; the MinIO documentation SHALL state the index as N/A and define access via object-name prefixes plus a client-side scan.

#### Scenario: Composite index exists in server-indexed engines
- **WHEN** indexes are inspected in PostgreSQL, TimescaleDB, MongoDB, and ClickHouse
- **THEN** a composite `(userId, timestamp)` index exists in each

#### Scenario: MinIO documents no server index
- **WHEN** the MinIO documentation is inspected
- **THEN** it states the index as N/A and describes access through day-prefixed object names plus a client-side scan

### Requirement: MinIO JSON Lines layout
MinIO SHALL store events as immutable JSON Lines objects partitioned by day, using the same logical event model as the other engines.

#### Scenario: Day-partitioned JSON Lines objects
- **WHEN** events are written to MinIO
- **THEN** each object is a `.jsonl` file stored under a `YYYY-MM-DD` day prefix and is never modified after upload

### Requirement: Engine compression settings
Each engine SHALL have reasonable, standard, supported compression enabled and documented: TimescaleDB compression explicitly enabled; PostgreSQL TOAST; MongoDB WiredTiger snappy; ClickHouse LZ4; MinIO no server-side compression.

#### Scenario: Compression matches the documented settings
- **WHEN** each engine's configuration and documentation are inspected
- **THEN** the active compression matches the documented setting for that engine

### Requirement: Phase-1 fairness constraints
The bench SHALL NOT apply field-name mapping or shortening, non-standard codec tricks, or phase-2 optimizations.

#### Scenario: Full logical field names and default codecs
- **WHEN** schemas and engine configuration are inspected
- **THEN** field names preserve the full logical names (`id`, `timestamp`, `userId`, `eventType`, `metadata`), allowing only an engine-native rendering of the same names (for example SQL snake_case `user_id` / `event_type`), and no field remapping, shortened names, or custom codecs are applied

### Requirement: Reproducibility
The bench SHALL be reproducible: the same Compose file, image tags, and configuration on a clean host SHALL yield the same configuration and measurement conditions.

#### Scenario: Identical configuration on a clean host
- **WHEN** the same artifact set is applied on a clean host
- **THEN** `docker compose config` output is identical and every engine starts with identical configuration

### Requirement: Capacity for 100 million records
The bench SHALL be ready to accept up to 100,000,000 records: resource and volume requirements SHALL be documented, and no hard limits below that volume SHALL exist.

#### Scenario: No limit below 100M records
- **WHEN** the bench documentation is inspected
- **THEN** it states readiness for 100,000,000 records and no configured quota or storage limit caps the engines below that volume

### Requirement: Healthy and reachable stack
After `docker compose up -d`, all five containers SHALL reach a healthy state and each engine SHALL respond to requests, verifiable programmatically.

#### Scenario: All engines healthy and responding
- **WHEN** `docker compose up -d` completes and health checks run
- **THEN** all five services report healthy and each engine responds to a health/ping query

### Requirement: English public artifacts
All public bench artifacts — README, config comments, methodology documentation, and measurement report templates — SHALL be written in English.

#### Scenario: English documentation
- **WHEN** the bench artifacts are inspected
- **THEN** all user-facing text and comments are in English
