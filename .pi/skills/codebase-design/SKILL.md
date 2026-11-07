---
name: codebase-design
description: >
  Designing deep modules: interface, seam, depth/leverage/locality. Use when designing or improving module interfaces, choosing where a seam goes, or improving testability and code navigability.
---

# Codebase Design: deep modules

Design **deep modules**: a lot of behavior behind a small interface, at a clean seam, testable through that interface. The aim is leverage for callers, locality for maintainers, and testability for everyone.

## Glossary

- **Module** — anything with an interface and an implementation (function, class, package).
- **Interface** — everything a caller must know to use it correctly: signature + invariants + ordering constraints + error modes + configuration + performance characteristics.
- **Implementation** — what's inside a module.
- **Depth** — leverage at the interface: how much behavior a caller gets per unit of interface learned.
- **Seam** — where a module's interface lives; where you can change behavior without editing that place.
- **Adapter** — a concrete thing that satisfies an interface at a seam.
- **Leverage** — what callers get from depth.
- **Locality** — what maintainers get: changes/bugs/knowledge/verification concentrate in one place.

## Deep vs shallow

- **Deep** = small interface + lots of implementation. ✓
- **Shallow** = large interface + thin implementation (pass-through). ✗

Questions when designing an interface: fewer methods? simpler parameters? hide more complexity inside?

## Principles

- **Depth is a property of the interface, not the implementation.** Inside, a module may be composed of small swappable parts; they are not part of the interface.
- **The deletion test.** Imagine deleting the module: if complexity vanishes, it was a pass-through; if complexity reappears across N callers, it was earning its keep.
- **The interface is the test surface.** Callers and tests cross the same seam. If you want to test *past* the interface, the module is probably the wrong shape.
- **One adapter means a hypothetical seam. Two adapters means a real one.** Don't introduce a seam unless something actually varies across it.

## Designing for testability

1. **Accept dependencies, don't create them.**

   ```java
   // testable
   void processOrder(Order order, PaymentGateway gateway) {}

   // hard to test
   void processOrder(Order order) {
       var gw = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects.**

3. **Small surface area.** Fewer methods = fewer tests; simpler parameters = simpler setup.
