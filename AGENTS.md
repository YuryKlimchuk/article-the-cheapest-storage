<!-- AgentCraft workflow (installed by setup.sh) -->
# Project Instructions

This repository follows the **AgentCraft** development workflow for AI-assisted software development.

## Workflow

Development follows eight stages coordinated by the Orchestrator (the leading coding agent):

1. Preparation
2. Analyst
3. Architect
4. QA Planning
5. Developer
6. Reviewer
7. QA Testing
8. Finalization and Pull Request

- Stage details and transitions: `docs/agentcraft/workflow.md`
- Orchestrator role and delegation rules: `docs/agentcraft/orchestrator.md`
- Quality-gate pass conditions: `docs/agentcraft/quality-gates.md`

## Quality gates

| Gate | What it checks |
|------|----------------|
| G1 | Repository, task, and environment are ready |
| G2 | Requirements and Acceptance Criteria are approved |
| G3 | OpenSpec artifacts are prepared |
| G4 | Test plan and technical solution are approved |
| G5 | Build and primary development checks pass |
| G6 | Independent code review passes |
| G7 | QA passes (or user-confirmed manual verification) |
| G8 | All stages complete, Pull Request ready |

## Working principles

- User approval at defined checkpoints; no implementation before requirements, design, and Test plan are approved.
- Prefer deterministic, programmatic verification over self-reported "done".
- Keep implementation, code review, and QA testing as separate responsibilities.
- Simplicity: no premature abstractions.

<!-- Add project-specific instructions below this line. -->
