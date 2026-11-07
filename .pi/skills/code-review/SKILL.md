---
name: code-review
description: >
  Two-axis code review of changes: Standards (repo conventions + Fowler smell baseline) and Spec (conformance to approved requirements/OpenSpec artifacts). Use when reviewing a diff, branch, PR, or WIP changes.
---

# Two-axis code review

Review the diff between `HEAD` and a fixed point along **two axes**:

- **Standards** — does the code follow this repo's documented coding standards?
- **Spec** — does the code faithfully implement the approved requirements / OpenSpec artifacts?

Run both axes **separately** and do not mix findings — one axis must not mask the other.

## Process

### 1. Pin the fixed point

`git diff <fixed-point>...HEAD` (three-dot, comparison against the merge-base). Commit list: `git log <fixed-point>..HEAD --oneline`. Verify the ref resolves and the diff is non-empty.

### 2. Find the spec source

In order:

1. Approved requirements and Acceptance Criteria (from Analyst).
2. OpenSpec artifacts: Proposal, Specs, Design, Tasks.
3. Task references in commit messages.
4. If none — report "no spec available", and the Spec axis is skipped.

### 3. Find the standards sources

Look for files that document how code should be written: `CODING_STANDARDS.md`, `CONTRIBUTING.md`, `AGENTS.md`. Always apply the **smell baseline** below.

Smell baseline (Fowler, *Refactoring*, ch. 3) — always applies:

- **Mysterious Name** → rename it.
- **Duplicated Code** → extract the shared shape.
- **Feature Envy** → move the method onto the data it envies.
- **Data Clumps** → bundle into one type.
- **Primitive Obsession** → give the concept its own type.
- **Repeated Switches** → replace with polymorphism or one shared map.
- **Shotgun Surgery** → gather what changes together into one module.
- **Divergent Change** → split the module.
- **Speculative Generality** → delete it until a real need shows.
- **Message Chains** → hide the walk behind one method.
- **Middle Man** → call the real target directly.
- **Refused Bequest** → use composition instead of inheritance.

Rules:

- **A documented repo standard wins** over the baseline smell.
- Each smell is a heuristic ("possible Feature Envy"), not a hard violation.
- Skip anything tooling already enforces.

### 4. Assess both axes

Per axis, per file/hunk:

- **(a)** standard violations with a citation of the rule;
- **(b)** smells with a quote of the hunk; distinguish hard violations from judgement calls.

For Spec:

- **(a)** requirements that are missing or partial;
- **(b)** behavior that wasn't asked for (scope creep);
- **(c)** implemented but looks wrong. Quote the requirement line for each finding.

### 5. Report

Separate `## Standards` and `## Spec` sections. End with a summary: findings per axis and the worst issue within each axis.

## Why two axes

- Code that follows every standard but does the wrong thing → Standards pass, Spec fail.
- Code that does exactly what was asked but breaks conventions → Spec pass, Standards fail.

Separate reporting keeps one axis from masking the other.
