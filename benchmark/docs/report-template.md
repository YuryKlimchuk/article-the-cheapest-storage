# Measurement Report Template

One table per measured dataset size. Record bytes as reported; do not convert.

## Dataset size: `<N>` records

Image digests (record at run time with `docker compose -f benchmark/docker-compose.yml images`):

| Service       | Image                                      | Digest |
|---------------|--------------------------------------------|--------|
| `postgres`    | `postgres:16.6`                            |        |
| `timescaledb` | `timescale/timescaledb:2.17.2-pg16`        |        |
| `mongodb`     | `mongo:7.0.14`                             |        |
| `clickhouse`  | `clickhouse/clickhouse-server:24.8`        |        |
| `minio`       | `pgsty/silo:RELEASE.2026-10-26T00-00-00Z`  |        |

## Engine × on-disk size (bytes)

| Metric                 | PostgreSQL | TimescaleDB | MongoDB | ClickHouse | MinIO |
|------------------------|-----------:|------------:|--------:|-----------:|------:|
| **Headline** (data + `(userId, timestamp)` index, WAL/journals excluded) | | | | | |
| WAL / journal          |           |            |         | n/a        | n/a  |
| Data                   |           |            |         |            |      |
| `(userId, timestamp)` index |       |            |         |            | n/a  |
| Other unavoidable index (e.g. MongoDB `_id`) | n/a | n/a |   | n/a        | n/a  |
| MinIO `.minio.sys` overhead | n/a    | n/a        | n/a     | n/a        |      |

Notes:

- **Headline** = settled data + `(userId, timestamp)` index, excluding
  WAL/journals and container images (see `methodology.md` section 5).
- **WAL / journal** is `pg_wal` for PostgreSQL/TimescaleDB and `journal` for
  MongoDB; ClickHouse and MinIO have no separate journal row.
- **Data vs index** rows come from each engine's native size report
  (`pg_total_relation_size` / `hypertable_detailed_size` / `collection.stats`
  / `system.parts` / `mc du`), not from `du -sb`.
- **MinIO** headline equals object bytes (`mc du`); its `du -sb` volume size
  additionally includes `.minio.sys` metadata, recorded in the overhead row.
- MongoDB's headline is inclusive of the mandatory `_id` index; report it in
  the "Other unavoidable index" row for transparency.

## Reproduce

```bash
# settle + measure each engine, then fill in the table above
# see benchmark/docs/methodology.md for exact commands
```
