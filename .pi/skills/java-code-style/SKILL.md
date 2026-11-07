---
name: java-code-style
description: >
  Java code style conventions. Use Objects.requireNonNull, StringUtils.isBlank,
  CollectionUtils.isEmpty, and other Apache Commons / JDK utility methods instead of
  manual null checks and conditionals. Prefer utility classes over raw expressions.
  Triggers when the user asks about Java code style, code conventions, or writing Java code.
---

# Java Code Style

When writing or refactoring Java code, follow these conventions.

## Null checks

```java
// ❌
if (s != null) { ... }
if (s == null) throw new ...;

// ✅
if (Objects.nonNull(s)) { ... }
Objects.requireNonNull(s, "s must not be null");
```

Use `java.util.Objects`:
- `Objects.requireNonNull(value, message)` — fail-fast with message
- `Objects.nonNull(value)` — boolean check
- `Objects.isNull(value)` — negation check

## String checks

```java
// ❌
if (s == null || s.isBlank()) { ... }
if (!s.isEmpty()) { ... }

// ✅
if (StringUtils.isBlank(s)) { ... }
if (StringUtils.hasText(s)) { ... }
```

Use `org.apache.commons.lang3.StringUtils`.

## Collection checks

```java
// ❌
if (list.size() == 0) { ... }
if (list == null || list.isEmpty()) { ... }

// ✅
if (CollectionUtils.isEmpty(list)) { ... }
if (CollectionUtils.isNotEmpty(list)) { ... }
```

Use `org.apache.commons.collections4.CollectionUtils`.

## Stream filtering

```java
// ❌
.map(optional -> optional.orElse(null))
.filter(x -> x != null)

// ✅
.flatMap(Optional::stream)
```

Prefer `Optional::stream` over null-based filtering.

## General principles

- Use `@RequiredArgsConstructor` from Lombok instead of explicit constructors for dependency injection
- Exceptions: explicit constructors OK when calling `super(message)`, `@Value` parameters, custom init logic, or `sealed` classes with super() calls
- Use `Objects.equals(a, b)` for null-safe equality instead of `a.equals(b)` or `a == b`
- Prefer declarative over imperative: utility methods over manual conditionals
- Fail-fast with meaningful messages in `requireNonNull`
- Null-safe by default: assume things can be null, guard accordingly
