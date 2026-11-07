# OpenSpec in AgentCraft

OpenSpec manages change specifications and engineering artifacts. In the AgentCraft workflow it is used by the **Architect** stage (G3), which prepares the Proposal, Specs, Design, and Tasks.

## Role in the workflow

- **Architect** prepares OpenSpec artifacts based on the approved requirements (from Analyst).
- **G3** confirms artifact readiness, not final approval.
- **G4** (after QA Planning) is the user's final approval of the whole package.

## Change artifacts

| Artifact | Contents |
|----------|----------|
| `proposal.md` | Why, What Changes, Capabilities, Impact, Non-goals |
| `specs/<capability>/spec.md` | `SHALL`/`MUST` requirements + `Scenario` (`WHEN`/`THEN`) |
| `design.md` | Decisions (D1, D2…), dependencies, trade-offs, risks |
| `tasks.md` | Implementation checklist: `- [ ] N.M <action>` |
| `test-plan.md` | QA Planning output: scope, levels, scenarios, acceptance mapping, environment, risks, entry/exit criteria |

`specs` is the "what" (behavior), `design` is the "how", `tasks` are concrete implementation steps.

## Architect workflow

```bash
openspec context --json                                   # OpenSpec root
openspec new change "<N>-<name>"                          # create the change
openspec instructions <artifact-id> --change "<name>" --json  # template and instructions
openspec status --change "<name>"                         # verify readiness
```

Create artifacts in dependency order, following the `template` and writing to `resolvedOutputPath`.

## AgentCraft conventions

- **Change numbering**: `<N>-<name>`, where `N` is the sequential proposal index (counting active and archived changes in `openspec/changes/` and `openspec/changes/archive/`).
- **Requirements**: atomic, with `SHALL`/`MUST`, subject + action + verifiable result. No unmeasured value words.
- **Scenario**: `WHEN` (condition/action) → `THEN` (observable result). At least one success scenario per non-trivial requirement.

## Configuration

`openspec/config.yaml` — `spec-driven` schema, artifact rules, and `apply`/`archive` guidance. It is distributed to target repositories by the AgentCraft setup script.

## Relationship to QA

- `qa-planner` assesses the artifacts and writes `test-plan.md` (the Test plan) into the change directory.
- `qa-tester` verifies the implementation against the Test plan (`test-plan.md`).
