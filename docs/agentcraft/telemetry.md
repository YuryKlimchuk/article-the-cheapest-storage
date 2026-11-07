# AgentCraft — Stage telemetry

After each workflow stage, the Orchestrator records how much time and how many tokens the stage
consumed, so every run is measurable and comparable.

## Who measures

The **Orchestrator** measures and records. Subagents do not self-report their own usage; the
Orchestrator reads the run result returned by `subagent()` (or `subagent({ action: "status", id })`
for async runs).

## Source fields

Each subagent run result exposes at least:

| Field | Meaning |
|-------|---------|
| `durationMs` | wall-clock duration of the run |
| `totalTokens` | cumulative token usage |
| `totalCost` | cumulative cost |
| `turnCount` | number of turns |
| `toolCount` | number of tool calls |
| `model` | resolved model |

## Table format

One row per stage, appended when the stage finishes (before the next Quality Gate is evaluated):

```
| # | Stage | Agent | Duration (s) | Tokens | Cost | Turns | Model |
|---|-------|-------|--------------|--------|------|-------|-------|
| 1 | Preparation | orchestrator | 12 | — | — | — | — |
| 2 | Analyst | analyst | 184 | 41,200 | $0.12 | 6 | … |
```

## Rules

- **Stages 2–7** (Analyst → QA Tester) are subagent runs: record `durationMs`, `totalTokens`,
  `totalCost`, `turnCount`, `toolCount`, and `model` from the run result.
- **Stages 1 and 8** (Preparation, Finalization) are performed by the Orchestrator itself:
  record only wall-clock time. The Orchestrator's own token usage belongs to the parent session
  and is not attributable per stage — leave the token columns empty and use `/subagent-cost` for
  the whole-run total when needed.
- Record duration as the stage's own wall-clock time; for subagent stages this is `durationMs`.
- Store the table in the workflow report; when an OpenSpec change exists, also save it as
  `openspec/changes/<name>/telemetry.md`.
