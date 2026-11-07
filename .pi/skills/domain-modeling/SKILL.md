---
name: domain-modeling
description: >
  Sharpening a project's domain model: GLOSSARY.md (terms) and ADRs (decision records). Use when discussing domain terminology, creating/editing a glossary, or recording architectural decisions.
---

# Domain Modeling

Actively build and sharpen the domain model as you design: challenge terms, invent edge-case scenarios, and record the glossary and decisions the moment they crystallize.

## Files

```
/
├── GLOSSARY.md        ← domain terms (no implementation details)
└── docs/adr/          ← architectural decisions
    └── 0001-....md
```

Create files lazily — only when there is something to write.

## During the session

- **Challenge against the glossary.** A term conflicts with `GLOSSARY.md` — call it out: "The glossary defines X, but you seem to mean Y."
- **Sharpen fuzzy language.** A vague/overloaded term → propose a precise canonical one: "'account' — Customer or User?"
- **Discuss concrete scenarios.** Stress-test domain relationships with edge cases that force precision about boundaries.
- **Cross-reference with code.** A contradiction between words and code — surface it.
- **Update `GLOSSARY.md` inline**, not in batches. The glossary is terms only — no implementation details, spec, or scratch.

## ADRs — only when all three hold

1. **Hard to reverse** — the cost of changing the decision later is meaningful.
2. **Surprising without context** — a future reader will wonder "why this way?".
3. **The result of a real trade-off** — there were alternatives and one was chosen for reasons.

If any is missing, skip the ADR.

ADR format: a heading with number and topic; `Status`; `Context`; `Decision`; `Consequences`.
