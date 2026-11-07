# Tasks

## 1. Scaffold and Docker Compose bench

- [ ] 1.1 Create the bench directories `benchmark/init/postgres`, `benchmark/init/timescaledb`, `benchmark/init/mongodb`, `benchmark/init/clickhouse`, and `benchmark/docs` and verify each directory exists with `ls -d`
- [ ] 1.2 Create `benchmark/docker-compose.yml` with the five services (`postgres`, `timescaledb`, `mongodb`, `clickhouse`, `minio`), the pinned tags from design D2, the host ports from D3, and credentials/database names from D4, and verify `docker compose -f benchmark/docker-compose.yml config` validates without errors
- [ ] 1.3 Add one named volume per service (D5) with no bind mounts or anonymous data volumes and no replication/sharding flags (D6), and verify `docker compose -f benchmark/docker-compose.yml config` shows exactly five services and five top-level named volumes and no `replSet`/replication directives
- [ ] 1.4 Add a `healthcheck` to each service (D12) and verify the healthcheck commands are present in the validated Compose config
- [ ] 1.5 Write `benchmark/README.md` in English covering prerequisites, `docker compose up -d`/`down`, host access strings, credentials, ports, healthcheck verification, MinIO bucket creation, and the 100M-record capacity note (D17), and verify the documented `docker compose up -d` command is stated exactly as it will run

## 2. Per-engine init scripts (schema, index, compression)

- [ ] 2.1 Write `benchmark/init/postgres/001-schema.sql` with the native ENUM type, the `audit_events` table (UUID/TIMESTAMPTZ/BIGINT/JSONB) and the composite `(user_id, timestamp)` index, in English, and verify after startup that `psql -c '\d audit_events'` lists the five fields and the index
- [ ] 2.2 Write `benchmark/init/timescaledb/001-schema.sql` with the same table plus `create_hypertable`, the composite index, and explicit compression (D10), in English, and verify after startup that `psql -c '\d+ audit_events'` and `hypertable_detailed_size` show a hypertable with compression enabled and the index present
- [ ] 2.3 Write `benchmark/init/mongodb/001-schema.js` creating the `audit_events` collection and the `{ userId: 1, timestamp: 1 }` index, in English, and verify after startup that `db.audit_events.getIndexes()` includes the composite index
- [ ] 2.4 Write `benchmark/init/clickhouse/001-schema.sql` creating `benchmark.audit_events` on MergeTree with `ORDER BY (user_id, timestamp)`, native types (`UUID`, `DateTime64(3, 'UTC')`, `Int64`, `Enum8`, `String`), in English, and verify after startup that `DESCRIBE TABLE` shows the five columns and `system.tables` shows `primary_key = user_id, timestamp`
- [ ] 2.5 Document the MinIO bucket `audit-events`, the day-partitioned JSON Lines layout (D9), and the exact `mc` bucket-creation command, in English, and verify the documented command creates the bucket

## 3. Measurement methodology and report template

- [ ] 3.1 Write `benchmark/docs/methodology.md` in English with the primary `du -sb` method over each named volume mountpoint, the per-engine settle procedures (D13), the engine-internal cross-check commands (D15), and the headline metric definition with separate WAL/journal and data-vs-index rows (D14), and verify every listed command is syntactically exact and reproducible
- [ ] 3.2 Write `benchmark/docs/report-template.md` in English with an engine × dataset-size table containing headline, WAL/journal, and data-vs-index rows (plus the MinIO `.minio.sys` overhead row), and verify the template columns match the rows defined in `methodology.md`

## 4. Integration verification

- [ ] 4.1 Run `docker compose -f benchmark/docker-compose.yml up -d` on a clean volume state and verify `docker compose ps` reports all five services `healthy` and each engine responds programmatically (`pg_isready` for both SQL engines, `mongosh` ping, `clickhouse-client 'SELECT 1'`, MinIO `/minio/health/live`)
- [ ] 4.2 Re-run the checks from tasks 2.1-2.4 against the running stack and verify the schema, composite index, and compression are present in PostgreSQL, TimescaleDB, MongoDB, and ClickHouse
- [ ] 4.3 Smoke-test the methodology on empty volumes by executing each engine's settle procedure and recording `du -sb` plus the cross-check value, and verify the commands complete and produce a byte count for each engine
