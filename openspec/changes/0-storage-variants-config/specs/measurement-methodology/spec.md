# Spec Delta

## Purpose

Defines how on-disk footprint is measured for each storage engine: the primary `du -sb` method over the named volume, the per-engine settle procedure, engine-internal cross-checks, and the headline metric with separate WAL/journal and data-vs-index rows.

## ADDED Requirements

### Requirement: Primary disk measurement method
The primary disk measurement SHALL be `du -sb` over the named volume's directory, executed after the per-engine settle procedure completes.

#### Scenario: Measure the settled named volume
- **WHEN** an engine's footprint is measured
- **THEN** `du -sb` is run over that engine's named-volume mountpoint after settle and its byte count is recorded

### Requirement: Per-engine settle procedure
A per-engine settle procedure SHALL be documented and executed before measurement, bringing each engine to a stable, fully-written state (checkpoint plus VACUUM / compression / OPTIMIZE as applicable).

#### Scenario: Settle runs before measuring
- **WHEN** an engine's footprint is measured
- **THEN** that engine's documented settle commands have completed successfully before `du -sb` is recorded

### Requirement: Engine-internal cross-check
Engine-internal size reports SHALL be recorded as a cross-check alongside the `du -sb` value, using each engine's native size reporting (for example `pg_total_relation_size`, `collection.stats().storageSize`, `system.parts`).

#### Scenario: Cross-check recorded with the measurement
- **WHEN** a measurement report is produced for an engine
- **THEN** the engine-internal size report for that engine is recorded next to its `du -sb` value

### Requirement: Headline metric definition
The headline metric SHALL be defined as settled on-disk bytes of data plus the `(userId, timestamp)` index, excluding WAL/journals and excluding container images; WAL/journals and data-vs-index SHALL be recorded as separate rows.

#### Scenario: Headline excludes WAL and images
- **WHEN** the headline metric is computed for an engine
- **THEN** the headline equals settled data-plus-index bytes with WAL/journal bytes and container images excluded

#### Scenario: Separate WAL and data-vs-index rows
- **WHEN** a measurement report is produced
- **THEN** WAL/journal bytes and data-vs-index bytes are present as rows separate from the headline

### Requirement: Reproducible English methodology
The measurement methodology documentation SHALL be in English and SHALL give exact, reproducible commands for every step.

#### Scenario: Exact reproducible English commands
- **WHEN** the methodology documentation is inspected
- **THEN** it is in English and every step lists the exact command to reproduce it
