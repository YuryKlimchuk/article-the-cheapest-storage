---
name: grill-me
description: Systematic user interview to clarify a task and form requirements. Use during task analysis (Analyst stage) when there are ambiguities, unclear scope, or a need to make requirements unambiguous and verifiable.
---

# Grill-me: requirements-clarification interview

## Goal

Reach a **shared understanding** of the task: every decision and requirement is explicitly captured, no branch remains an implicit assumption. The result is unambiguous, verifiable requirements and Acceptance Criteria.

## Decision tree

Model the task as a **decision tree**: each decision branches into the decisions that depend on it. Branches are scope, behavior, constraints, priorities, and acceptance criteria.

## Rounds and frontier

Work in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask now without guessing answers you haven't heard yet.

In one round, ask the whole frontier: number each question and give a **recommended answer** to each. Then wait for the user's answers before the next round.

Round format:

```
❓ **Q1** — **<question title>**: <question body, with options if needed>

➡️ <your recommended answer>

---

❓ **Q2** — **<question title>**: <question body, with options if needed>

➡️ <your recommended answer>
```

Word each question so that "yes" accepts your recommendation.

After each round, the user's answers reshape the tree: settled decisions push the frontier outward and unblock new questions. A question that depends on another question still open in this round belongs to the **next** round, not the current one.

## Facts you find yourself, decisions belong to the user

- **Facts** (how the system behaves, what is in code and docs) — your job. Use `read`/`grep`/`find`/`ls`/`bash` (read-only). Never ask the user for anything you can find out yourself.
- **Decisions** (scope, priorities, behavior, acceptance) — the user's. Put them via `contact_supervisor` (`reason: "need_decision"`) and wait for the reply.

## Requirement formulation

Turn each user answer into a verifiable requirement or Acceptance Criterion:
- atomic — one requirement = one behavior;
- with a `SHALL`/`MUST` modal verb;
- subject + action + verifiable result;
- Acceptance Criterion checkable as yes/no.

## Completion

The session ends when the frontier is empty: every branch of the decision tree visited, no implicit assumptions left. Do not return final requirements until the user confirms you have reached a shared understanding.

## Stop signals

- **Passive user.** A series of "yes, yes, yes" without their own decisions is unproductive: you may not be asking real questions. Clarify what the user actually decides, and do not substitute your decision for theirs.
- **Unresolvable by talking.** Some questions (feel, layout, aesthetics) cannot be resolved in words — they need a prototype or example to react to. Record such a question as open and continue the other branches.
- **Scope too large.** If the tree grows to hundreds of questions — suggest the user split the task and grill each part separately.
