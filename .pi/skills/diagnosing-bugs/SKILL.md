---
name: diagnosing-bugs
description: >
  Disciplined diagnosis of bugs and performance regressions: feedback loop → minimize → ranked hypotheses → instrument → fix with regression test → cleanup. Use when diagnosing "why is it broken/crashing/slow".
---

# Diagnosing Bugs

A discipline for hard bugs. Skip phases only with explicit justification.

## Redact

When showing commands/outputs/artifacts, replace secrets with `<REDACTED>` first. Build loops against env vars so credentials stay in the environment.

## Phase 1: Build a feedback loop

**This is the skill.** You need a tight pass/fail signal that goes red on *this* bug. Without it, no amount of code reading helps.

Ways to build one, in roughly this order:

1. A failing test at whatever seam reaches the bug.
2. A curl/HTTP script against a running server.
3. A CLI invocation with a fixture, diffing stdout against a known-good snapshot.
4. A headless browser script (Playwright/Puppeteer).
5. Replay a captured trace (request/payload/log).
6. A throwaway harness — a minimal slice of the system.
7. Property/fuzz — many random inputs.
8. A bisection harness — `git bisect run`.
9. A differential loop (old vs new version).
10. A HITL script — if a human is needed.

**Tighten the loop**: faster (cache, narrow scope), sharper signal (assert the specific symptom), more deterministic (pin time/RNG/filesystem/network). A 30-second flaky loop is barely useful; a 2-second deterministic one is a superpower.

**Non-deterministic bugs**: the goal is not a clean repro but a **higher reproduction rate**. Loop the trigger many times, add stress, narrow timing windows.

**If you genuinely cannot build a loop** — stop and say so explicitly. List what you tried. Ask for environment access, an artifact, or permission for temporary instrumentation. Do not proceed to hypotheses without a loop.

Phase 1 done criterion: one command you have **already run**, that is:

- [ ] red-capable on *this* bug (not "ran without erroring");
- [ ] deterministic;
- [ ] fast (seconds);
- [ ] runnable without a human.

## Phase 2: Reproduce + minimize

- Confirm the loop produces **the exact** failure the user described, not a nearby one.
- Minimize the repro to the smallest scenario that still goes red. Cut inputs/config/data one at a time, re-running the loop.
- Done when every remaining element is load-bearing: removing any one turns it green.

## Phase 3: Hypothesize

Generate **3–5 ranked hypotheses** before testing any. Each must be **falsifiable**: "If X is the cause, then changing Y removes the bug / changing Z worsens it." Can't state the prediction — it's a vibe, drop or sharpen it.

Show the ranked list to the user (domain knowledge often re-ranks it), but don't block — proceed with your ranking if the user is away.

## Phase 4: Instrument

Each probe must map to a specific prediction from Phase 3. **Change one variable at a time.**

1. Debugger/REPL if the environment supports it (one breakpoint beats ten logs).
2. Targeted logs at boundaries that distinguish hypotheses.
3. Never "log everything and grep".

Tag debug logs with a unique prefix `[DEBUG-xxxx]` — cleanup becomes a single grep.

**Performance regressions**: logs are usually wrong. Establish a baseline measurement (profiler/query plan), then bisect. Measure before fixing.

## Phase 5: Fix + regression test

Write the regression test **before the fix**, only if there is a correct seam. If no correct seam exists, that itself is the finding (the architecture prevents locking the bug down) — note it.

If a seam exists: minimized repro → failing test → fix → test green → re-run the Phase 1 loop.

## Phase 6: Cleanup

- [ ] original repro no longer reproduces;
- [ ] regression test passes (or the absence of a seam is documented);
- [ ] `[DEBUG-...]` instrumentation removed;
- [ ] throwaway prototypes removed;
- [ ] the correct hypothesis stated in the commit/PR message.
