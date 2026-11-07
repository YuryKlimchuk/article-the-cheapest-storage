# AgentCraft — Quality Gates (details)

This document details the pass conditions for each workflow Quality Gate. The workflow overview and stage descriptions are in [docs/workflow.md](workflow.md).

## Summary table

| Gate | What it checks |
|------|----------------|
| G1 | Repository, task, and environment are ready |
| G2 | Requirements and Acceptance Criteria are approved |
| G3 | OpenSpec artifacts are prepared |
| G4 | Test plan and technical solution are agreed |
| G5 | Build and primary Developer checks pass |
| G6 | Independent code review passes |
| G7 | QA passes, or the user confirms manual verification |
| G8 | All mandatory stages are complete, PR data is ready |

> **Note on G3 and G4.** G3 means the Architect's artifacts are ready, not final user approval. Final approval of the whole package happens at G4, after QA Planning.
>
> **Note on G8.** G8 does not re-run testing: it verifies that confirmed results from previous stages exist.

---

## G1 — Repository, task, and environment are ready

**Stage:** Preparation.

**What it checks:** readiness of the task, repository, and working environment to start the workflow.

**Pass conditions (checklist):**

- [ ] The task is captured: original task description and a reference to its source exist.
- [ ] The target repository is identified and accessible (read; write when needed).
- [ ] No conflicts with workflows already running in this repository.
- [ ] The base branch is identified; a working branch is created from its current state and checked out.
- [ ] Task context is stored (original task and relevant artifacts).
- [ ] The workflow is initialized: initial state is captured and workflow artifact storage is prepared.

**On failure:** return to Preparation and resolve the blockers.

---

## G2 — Requirements and Acceptance Criteria are approved

**Stage:** Analyst.

**What it checks:** completeness and agreement of requirements before technical design.

**Pass conditions (checklist):**

- [ ] Requirements are captured in a document.
- [ ] Acceptance Criteria are formulated and unambiguous.
- [ ] Ambiguities are resolved, clarification questions are closed.
- [ ] Clarification decisions are recorded.
- [ ] The user has explicitly approved the final requirements.

**On failure:** return to Analyst.

---

## G3 — OpenSpec artifacts are prepared

**Stage:** Architect.

**What it checks:** readiness of the technical solution for independent QA assessment.

**Pass conditions (checklist):**

- [ ] OpenSpec Proposal is prepared.
- [ ] Specs are updated or created.
- [ ] Design document is ready.
- [ ] Implementation Tasks are formulated.
- [ ] The solution is consistent with the approved requirements and project conventions.

**On failure:** return to Architect.

> **Important:** G3 confirms artifact readiness, not final approval. Final approval of the package happens at G4.

---

## G4 — Test plan and technical solution are agreed

**Stage:** QA Planning.

**What it checks:** consistency of the technical documentation and the verification plan; readiness for implementation.

**Pass conditions (checklist):**

- [ ] Test plan is prepared (scope, levels, scenarios, acceptance mapping, environment, risks, entry/exit criteria).
- [ ] Test scenarios are mapped to Acceptance Criteria (traceability).
- [ ] Identified risks are addressed or explicitly accepted by the user.
- [ ] Technical documentation and Test plan are consistent with each other.
- [ ] The user has approved the whole documentation package.

**On failure:** return to Architect (when the solution is updated, QA Planning is repeated).

---

## G5 — Build and primary Developer checks pass

**Stage:** Developer.

**What it checks:** implementation completeness and passing primary development checks.

**Pass conditions (checklist):**

- [ ] The required changes are implemented.
- [ ] Tests are added or updated.
- [ ] The build passes.
- [ ] Unit, integration, and other applicable checks pass.
- [ ] The implementation matches the approved architecture and project conventions.

**On failure:** return to Developer.

---

## G6 — Independent code review passes

**Stage:** Reviewer.

**What it checks:** independent confirmation of implementation quality.

**Pass conditions (checklist):**

- [ ] Code review is performed independently of development.
- [ ] The implementation matches requirements and the approved architecture.
- [ ] Code quality and maintainability are acceptable.
- [ ] Tests are sufficient and cover the required scenarios.
- [ ] All findings are resolved; review is approved.

**On failure:** return to Developer.

> **Important:** Code review does not replace functional QA testing.

---

## G7 — QA passes, or the user confirms manual verification

**Stage:** QA Testing.

**What it checks:** a positive result of verifying the actual implementation.

**Pass conditions (checklist):**

- [ ] All planned Test plan scenarios are executed.
- [ ] Automated verification finished with `PASSED`, **or** manual verification was performed and confirmed by the user.
- [ ] Defects are absent, or fixed and re-verified.

**On failure:** return to Developer; after code changes, re-run Reviewer, then QA Testing.

> **Important:** `MANUAL_VERIFICATION_REQUIRED` is not a successful QA result. Success is `PASSED` or user-confirmed manual verification.

---

## G8 — All mandatory stages are complete, PR data is ready

**Stage:** Finalization and Pull Request.

**What it checks:** presence of confirmed results from all previous stages and readiness to publish the PR.

**Pass conditions (checklist):**

- [ ] All mandatory workflow stages are complete.
- [ ] Developer checks passed (G5).
- [ ] Reviewer approved the implementation (G6).
- [ ] QA Testing has a confirmed positive result (G7).
- [ ] Workflow artifacts are collected (requirements, OpenSpec docs, Test plan, check results, reports, stage telemetry).
- [ ] The Pull Request is created and the user is notified.

**On failure (depends on cause):**

- Missing or incomplete results from a mandatory stage (G5/G6/G7) → return to the stage that actually failed (see the rollback table in [orchestrator.md](orchestrator.md)).
- Branch publication or Pull Request creation failed (temporary or infrastructure error) → retry Finalization; do not return to Developer — the code is already verified.
- Permission or configuration error (cannot push / create the PR) → ask the user for a decision.

> **Important:** G8 does not re-run testing. It verifies that confirmed results from previous stages exist.
