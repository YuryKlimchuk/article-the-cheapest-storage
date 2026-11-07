# AgentCraft Workflow Orchestrator

The Orchestrator is the **role of the leading Pi agent** that coordinates the workflow. It is neither a separate subagent nor an orchestration runtime.

The Orchestrator runs the process according to [`workflow.md`](workflow.md) and checks transitions against [`quality-gates.md`](quality-gates.md), delegating stages to subagents via `pi-subagents`.

## Responsibilities

1. Drive the process through the eight stages.
2. Launch subagents with the right context.
3. Verify every Quality Gate.
4. Request user approval at checkpoints.
5. Pass artifacts between stages.
6. Handle rollbacks and failures.

## Stage map

| # | Stage | Performed by | Gate | User approval |
|---|-------|--------------|------|---------------|
| 1 | Preparation | Orchestrator | G1 | no |
| 2 | Analyst | `analyst` | G2 | **yes** — requirements and AC |
| 3 | Architect | `architect` | G3 | no (artifact readiness only) |
| 4 | QA Planning | `qa-planner` | G4 | **yes** — whole documentation package |
| 5 | Developer | `dev-implementer` | G5 | no |
| 6 | Reviewer | `dev-reviewer` | G6 | no |
| 7 | QA Testing | `qa-tester` | G7 | **yes** — manual verification only |
| 8 | Finalization | Orchestrator | G8 | no (Orchestrator creates the PR, user merges) |

## How to launch subagents

```js
subagent({
  agent: "analyst",
  task: "<original task + links to relevant documentation>",
  async: true
})
// wait() when the result is needed
```

In `task` always pass:
- what to do;
- links to input artifacts (requirements, OpenSpec artifacts, Test plan);
- role boundaries and what **not** to do;
- the expected output shape.

## Approval checkpoints

- **G2** — show the user the requirements and Acceptance Criteria, wait for explicit approval.
- **G4** — show the package (Proposal + Specs + Design + Tasks + Test plan), wait for explicit approval.
- **G7 (manual verification)** — pass manual verification instructions, wait for the result.

**Implementation does not start before G4 passes.**

Other gates are Orchestrator checks, not user approvals:
- G1 — environment ready;
- G3 — Architect artifacts ready for QA assessment;
- G5 — build and primary checks pass;
- G6 — code review passes;
- G8 — all mandatory stages complete.

## Rollbacks (per workflow diagram)

| Failed | Return to |
|--------|-----------|
| G1 | repeat Preparation |
| G2 | `analyst` |
| G3 | `architect` |
| G4 | `architect` (then repeat `qa-planner`) |
| G5 | `dev-implementer` |
| G6 | `dev-implementer` |
| G7 | `dev-implementer` → after changes repeat `dev-reviewer` → then `qa-tester` |
| G8 | depends on cause — see "Finalization failures" below |

### Finalization failures (G8)

G8 has different failure classes and they must not be conflated:

- **Verification results missing/incomplete** — return to the stage whose result is actually missing (per the table above). Do not default to `dev-implementer`.
- **Publication failed** (branch push, PR creation) — the code is already verified; retry Finalization, do not change code.
- **Permission/config error** — ask the user for a decision instead of looping.

## Artifacts and traceability

Pass between stages and keep:
- requirements and AC (from `analyst`);
- OpenSpec artifacts: Proposal, Specs, Design, Tasks (in `openspec/`, from `architect`);
- Test plan and risks (from `qa-planner`);
- check results, review and QA reports;
- stage telemetry (time and tokens per stage, see [telemetry.md](telemetry.md)).

Keep the chain "requirement → design → implementation → verification" traceable: every artifact should reference its source.

## Stage telemetry

After each stage, the Orchestrator records one telemetry row (time, tokens, cost, turns, model)
and appends it to the run's telemetry table. Read the fields from the `subagent()` result; do not
ask the subagent to self-report usage. Full format and rules are in [telemetry.md](telemetry.md).

- Stages 2–7: read `durationMs`, `totalTokens`, `totalCost`, `turnCount`, `toolCount`, `model` from the run result.
- Stages 1 and 8: the Orchestrator records its own wall-clock time only; its tokens are part of the parent session and are not attributable per stage.
- Include the completed table in the final workflow report.

## Coordination with subagents

- Subagents escalate via `contact_supervisor` (`reason: "need_decision"`).
- The Orchestrator replies via `subagent_supervisor({ action: "reply", ... })`, or inspects pending asks via `subagent_supervisor({ action: "pending" })`.
- If a decision needs the user, pass the question to the user, then return the answer to the subagent.
- Findings from `qa-planner`, `dev-reviewer`, and `qa-tester` follow the shared format in [findings.md](findings.md); route them by `blocking` and `userDecisionRequired`, not by prose.

## Failure handling

- A subagent cannot proceed → preserve the current state and ask the user for a decision.
- Do not complete the workflow while stages or approvals remain outstanding.
- An agent's "work is done" statement is not proof of quality — verify gates against `quality-gates.md`.

## Performed by the Orchestrator itself

- **Preparation (G1):** accept the task and target repository, verify accessibility and absence of conflicts, prepare a working branch, store the original task.
- **Finalization (G8):** verify G5/G6/G7 passed, collect artifacts (including stage telemetry), prepare the final report, create the Pull Request, notify the user. G8 does not re-run testing.
