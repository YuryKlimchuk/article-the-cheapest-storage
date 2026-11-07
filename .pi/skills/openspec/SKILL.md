---
name: openspec
description: Working with OpenSpec change specifications — creating changes, preparing Proposal/Specs/Design/Tasks/Test plan, the SHALL/MUST + WHEN/THEN requirement format, and apply/archive. Use when working with OpenSpec artifacts or the openspec CLI.
---

# OpenSpec

OpenSpec manages change specifications. In AgentCraft it is used by the **Architect** stage (G3) and extended by the **QA Planning** stage (G4) with the **Test plan**.

## Change lifecycle

1. Create a change.
2. Prepare artifacts in dependency order (Proposal → Specs → Design → Tasks).
3. After QA Planning, add the Test plan.
4. Apply (implement), then archive.

## Artifacts

| Artifact | File | Contents |
|----------|------|----------|
| Proposal | `proposal.md` | Why, What Changes, Capabilities, Impact, Non-goals |
| Specs | `specs/<capability>/spec.md` | `SHALL`/`MUST` requirements + `Scenario` (`WHEN`/`THEN`) |
| Design | `design.md` | Decisions (D1, D2…), dependencies, trade-offs, risks |
| Tasks | `tasks.md` | Implementation checklist: `- [ ] N.M <action>` |
| Test plan | `test-plan.md` | QA Planning output (see below) |

`specs` is the "what" (behavior), `design` is the "how", `tasks` are concrete steps, `test-plan.md` is the verification contract.

## CLI workflow

```bash
openspec context --json                                   # locate the OpenSpec root
openspec new change "<N>-<name>"                          # create the change
openspec instructions <artifact-id> --change "<name>" --json  # template + instructions
openspec status --change "<name>"                         # verify readiness
```

Create artifacts in dependency order, following the `template` and writing to `resolvedOutputPath`. Do not copy `context`/`rules` into artifacts.

## Requirement format

- Atomic: one requirement = one behavior.
- Modal verb: `SHALL`/`MUST`.
- Subject + action + verifiable result.
- No unmeasured value words ("fast", "reliable", "scalable").
- Each non-trivial requirement has at least one `Scenario`: `WHEN` (condition/action) → `THEN` (observable result).

## Change numbering

`<N>-<name>`, where `N` is the sequential proposal index, counting active and archived changes in `openspec/changes/` and `openspec/changes/archive/`. The first proposal is `0`, then `1`, and so on.

## Test plan

The Test plan is produced by the **QA Planning** stage (`qa-planner`) after the Architect's artifacts, and lives in the change directory as `test-plan.md`.

Structure:

1. **Scope & goals** — what is tested and why.
2. **Test levels** — unit / slice / integration / e2e.
3. **Test scenarios** — positive, negative, boundary.
4. **Acceptance mapping** — scenarios mapped to Acceptance Criteria (traceability).
5. **Environment & data** — environment, dependencies, test data.
6. **Risks & assumptions** — risks and assumptions.
7. **Entry/exit criteria** — entry conditions and the G7 pass criteria.
