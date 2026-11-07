---
name: tdd
description: >
  Test-Driven Development (red→green→refactor): tests through the public interface (seams), anti-patterns, vertical slices. Use when implementing features or bugfixes, when tests are needed, or when the user asks for test-first.
---

# TDD

TDD is the red → green loop. This skill makes the loop meaningful: what a good test is, where tests go, anti-patterns, and loop rules.

## What a good test is

Tests verify **behavior through the public interface**, not implementation details. Code can change entirely; tests should survive. A good test reads like a specification: "a user can check out with a valid cart" states a capability, not the internals.

## Seams: where tests go

A **seam** is the public boundary where you observe behavior without reaching inside. Tests live at seams, never against internals.

**Test only at pre-agreed seams.** Before writing tests, capture which seams are under test and agree on them. You can't test everything — agreeing seams up front directs effort at critical paths and complex logic, not every edge case.

Ask: "What is the public interface, and which seams should we test?" Give each seam a one-liner: what it catches and what it misses.

If the shape of the interface is itself in question — consult the `codebase-design` skill (if available): it covers module depth, seam placement, and interfaces.

## Anti-patterns

- **Implementation-coupled**: mocks internal collaborators, tests private methods, or verifies through a side channel. The tell: the test breaks on refactor while behavior hasn't changed.
- **Tautological**: the assertion recomputes the expected value the same way the code does — the test passes by construction and can never disagree with the code. Expected values must come from an independent source of truth: a known-good literal, an example from the spec.
- **Horizontal slicing**: all tests first, then all implementation. Bulk tests verify imagined behavior and lock in structure before understanding the implementation. Work in **vertical slices**: one test → one implementation → repeat.

## Loop rules

- **Red before green.** Write the failing test first, then the minimum code to pass it. Don't anticipate future tests or add speculative features.
- **One slice at a time.** One seam, one test, one minimal implementation per cycle.
- **Refactoring is not part of the loop.** It belongs to the review stage (`dev-reviewer`), not the red→green cycle.
