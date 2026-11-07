# AgentCraft — Findings format

A **finding** is a single structured observation that an agent reports to the Orchestrator: a
defect, a risk, a question, or a recommendation. The Orchestrator routes findings by their
structure, not by prose judgment.

## Who emits findings

- `qa-planner` — review findings on the technical solution (G4).
- `dev-reviewer` — code review findings (G6).
- `qa-tester` — defects and verification findings (G7).

## Fields

Each finding is a short block:

```
### F<n>
- severity: blocker | major | minor | nit
- category: defect | risk | question | recommendation
- blocking: yes | no
- userDecisionRequired: yes | no
- recommendation: <one or two sentences on what to do>
- resolution: open | fixed | accepted | accepted-as-risk | rejected
```

| Field | Meaning |
|-------|---------|
| `severity` | Intrinsic importance. `blocker` — the current gate cannot pass until resolved. |
| `category` | Kind of finding. `question` always implies `userDecisionRequired: yes`. |
| `blocking` | `yes` — the current Quality Gate cannot pass until this finding is resolved. |
| `userDecisionRequired` | `yes` — needs the user; escalate instead of routing to an agent. |
| `recommendation` | Concrete proposed action. |
| `resolution` | Lifecycle state. `open` on creation; filled by whoever closes the finding. |

## Routing (for the Orchestrator)

| Condition | Action |
|-----------|--------|
| `blocking: yes`, `userDecisionRequired: no` | Return to the producing stage for correction. |
| `blocking: yes`, `userDecisionRequired: yes` | Escalate to the user for a decision. |
| `blocking: no` | Non-blocking; record it and proceed (may still be fixed later). |
| `category: question` | Always escalate to the user for a decision. |

## Resolution transitions

- agent fixes the finding → `fixed`;
- user accepts it as-is → `accepted`;
- user explicitly accepts the risk → `accepted-as-risk`;
- user rejects the finding → `rejected`.

A gate does not pass while any `blocking: yes` finding remains `open`.
